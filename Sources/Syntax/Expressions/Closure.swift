//
//  Created by Max Desiatov on 16/08/2021.
//

import Parsing

/** Closure expressions are always delimited by braces. Possible forms are:
 1. Empty closure `{}` of type `() -> ()`.
 2. Closures with parameters `{ a, b in x }` of type `(A, B) -> X`. Trailing commas for parameter names such as
 `{ a, b, in x }` are allowed.
 3. Multi-line closures that can contain multiple declarations with them. Expression on the last line of the closure
 is returned as a result, for example:
 ```
 { a, b in
   struct C { let a: Int}
   let c = { C[a: a] }
   c().a
 }
 ```
 */
public struct Closure<A: Annotation> {
  public typealias Body = [SyntaxNode<ExprBlock<A>.Element>]

  public enum Parameters {
    /// Undelimited parameters aren't delimited with parens and don't have type signatures.
    case undelimited([UndelimitedClosureParameter])

    /// Delimited parameters are delimited with parens and may have type signatures attached to them.
    case delimited(DelimitedSequence<DelimitedParameter>)

    func addAnnotation<NewAnnotation: Annotation>(
      _ transform: (Expr<A>) throws -> Expr<NewAnnotation>
    ) rethrows -> Closure<NewAnnotation>.Parameters {
      switch self {
      case let .undelimited(u):
        return Closure<NewAnnotation>.Parameters.undelimited(u)

      case let .delimited(d):
        return try Closure<NewAnnotation>.Parameters.delimited(d.map {
          try Closure<NewAnnotation>.DelimitedParameter(
            identifier: $0.identifier,
            typeSignature: $0.typeSignature?.addAnnotation(transform)
          )
        })
      }
    }

    public var typeSignatures: [SyntaxNode<Expr<A>>] {
      switch self {
      case .undelimited:
        return []
      case let .delimited(d):
        return d.elementsContent.compactMap(\.typeSignature?.signature)
      }
    }

    public var identifiers: [SyntaxNode<Identifier>] {
      switch self {
      case let .undelimited(u):
        return u.map(\.identifier)
      case let .delimited(d):
        return d.elementsContent.map(\.identifier)
      }
    }
  }

  public struct DelimitedParameter: SyntaxNodeContainer {
    public struct TypeSignature {
      public let colon: SyntaxNode<Empty>
      public let signature: SyntaxNode<Expr<A>>

      func addAnnotation<NewAnnotation: Annotation>(
        _ transform: (Expr<A>) throws -> Expr<NewAnnotation>
      ) rethrows -> Closure<NewAnnotation>.DelimitedParameter.TypeSignature {
        try .init(
          colon: colon,
          signature: signature.map(transform)
        )
      }
    }

    public let identifier: SyntaxNode<Identifier>
    public let typeSignature: TypeSignature?

    public var start: SyntaxNode<Empty> { identifier.empty }
    public var end: SyntaxNode<Empty> { typeSignature?.signature.empty ?? identifier.empty }
  }

  public let openBrace: SyntaxNode<Empty>
  public let parameters: Parameters
  public let inKeyword: SyntaxNode<Empty>?
  public let body: Body

  public let closeBrace: SyntaxNode<Empty>

  public var exprBlock: ExprBlock<A> {
    .init(openBrace: openBrace, elements: body, closeBrace: closeBrace)
  }

  public func addAnnotation<NewAnnotation: Annotation>(
    parameter parameterTransform: (Expr<A>) throws -> Expr<NewAnnotation>,
    body bodyTransform: (ExprBlock<A>) throws -> ExprBlock<NewAnnotation>
  ) rethrows -> Closure<NewAnnotation> {
    try .init(
      openBrace: openBrace,
      parameters: parameters.addAnnotation(parameterTransform),
      inKeyword: inKeyword,
      body: bodyTransform(exprBlock).elements,
      closeBrace: closeBrace
    )
  }
}

public struct UndelimitedClosureParameter {
  public let identifier: SyntaxNode<Identifier>
  public let comma: SyntaxNode<Empty>?
}

extension Closure: SyntaxNodeContainer {
  public var start: SyntaxNode<Empty> { openBrace }
  public var end: SyntaxNode<Empty> { closeBrace }
}

// FIXME: it's an awful hack, but it should work
extension Closure: Equatable {
  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.start == rhs.start && lhs.end == rhs.end
  }
}

extension Closure: Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(start)
    hasher.combine(end)
  }
}

private let nonParametricClosureParser = exprBlockParser
  .map {
    Closure(
      openBrace: $0.openBrace,
      parameters: .undelimited([]),
      inKeyword: nil,
      body: $0.elements,
      closeBrace: $0.closeBrace
    ).syntaxNode
  }

private let untypedParametersParser = Many(
  identifierParser()
    .take(commaParser)
)

private let closureBodyParser =
  Optional.parser(
    of: triviaParser(requiresLeadingTrivia: true, consumesNewline: true)
      .take(exprBlockElementsParser)
      .map { trivia, elements -> Closure<EmptyAnnotation>.Body in
        // Append required leading trivia to `ExprBlock` elements.
        [.init(leadingTrivia: trivia.map(\.content), content: elements[0].content)] + elements.dropFirst()
      }
  )
  .map { body -> [SyntaxNode<ExprBlock<EmptyAnnotation>.Element>] in
    guard let body = body else { return [] }
    return body
  }

private let parametricClosureParser = openBraceParser
  // Parses closures of form `{ a, b, c, in }`, note the trailing comma
  .take(
    untypedParametersParser
  )
  // Optional tail component without the comma to parse closures of form `{ a, b, c in }`
  .take(
    Optional.parser(of: identifierParser())
  )
  .take(Keyword.in.parser)
  .take(closureBodyParser)
  .take(closeBraceParser)
  .map { openBrace, head, tail, inKeyword, body, closeBrace -> SyntaxNode<Closure<EmptyAnnotation>> in
    let parameters: [UndelimitedClosureParameter]
    if let tail = tail {
      let headWithOptionalCommas = head.map { id, comma -> (SyntaxNode<Identifier>, SyntaxNode<Empty>?) in
        (id, comma)
      }

      parameters = (headWithOptionalCommas + [(tail, nil)])
        .map { UndelimitedClosureParameter(identifier: $0.0, comma: $0.1) }
    } else {
      parameters = head.map { UndelimitedClosureParameter(identifier: $0.0, comma: $0.1) }
    }

    return Closure(
      openBrace: openBrace,
      parameters: .undelimited(parameters),
      inKeyword: inKeyword,
      body: body,
      closeBrace: closeBrace
    ).syntaxNode
  }

private let delimitedParameterParser =
  identifierParser()
    .take(
      Optional.parser(
        of: colonParser
          .take(Lazy { exprParser() })
          .map(Closure<EmptyAnnotation>.DelimitedParameter.TypeSignature.init)
      )
    ).map {
      Closure<EmptyAnnotation>.DelimitedParameter(
        identifier: $0,
        typeSignature: $1
      ).syntaxNode
    }

let parametricWithTypesClosureParser =
  openBraceParser
    .take(
      delimitedSequenceParser(
        startParser: openParenParser,
        endParser: closeParenParser,
        separatorParser: commaParser,
        elementParser: delimitedParameterParser
      )
    )
    .take(Keyword.in.parser)
    .take(closureBodyParser)
    .take(closeBraceParser)
    .map {
      Closure(
        openBrace: $0,
        parameters: .delimited($1),
        inKeyword: $2,
        body: $3,
        closeBrace: $4
      ).syntaxNode
    }

let closureParser = parametricClosureParser
  .orElse(nonParametricClosureParser)
  .orElse(parametricWithTypesClosureParser)

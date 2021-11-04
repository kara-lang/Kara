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

  public struct Parameter {
    public let identifier: SyntaxNode<Identifier>
    // FIXME: parse type annotations
    public let typeSignature: SyntaxNode<Expr<A>>?
    public let comma: SyntaxNode<Empty>?

    func addAnnotation<NewAnnotation: Annotation>(
      _ transform: (Expr<A>) throws -> Expr<NewAnnotation>
    ) rethrows -> Closure<NewAnnotation>.Parameter {
      try .init(
        identifier: identifier,
        typeSignature: typeSignature?.map(transform),
        comma: comma
      )
    }
  }

  public let openBrace: SyntaxNode<Empty>
  public let parameters: [Parameter]
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
      parameters: parameters.map { try $0.addAnnotation(parameterTransform) },
      inKeyword: inKeyword,
      body: bodyTransform(exprBlock).elements,
      closeBrace: closeBrace
    )
  }
}

extension Closure.Parameter {
  init(identifier: SyntaxNode<Identifier>, comma: SyntaxNode<Empty>?) {
    self.init(identifier: identifier, typeSignature: nil, comma: comma)
  }
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

let nonParametricClosureParser = exprBlockParser
  .map {
    Closure(
      openBrace: $0.openBrace,
      parameters: [],
      inKeyword: nil,
      body: $0.elements,
      closeBrace: $0.closeBrace
    ).syntaxNode
  }

let parametricClosureParser = openBraceParser
  // Parses closures of form `{ a, b, c, in }`, note the trailing comma
  .take(
    Many(
      identifierParser()
        .take(commaParser)
    )
  )
  // Optional tail component without the comma to parse closures of form `{ a, b, c in }`
  .take(
    Optional.parser(of: identifierParser())
  )
  .take(Keyword.in.parser)
  .take(
    Optional.parser(
      of: triviaParser(requiresLeadingTrivia: true)
        .take(exprBlockElementsParser)
        .map { trivia, elements -> Closure<EmptyAnnotation>.Body in
          // Append required leading trivia to `ExprBlock` elements.
          [.init(leadingTrivia: trivia.map(\.content), content: elements[0].content)] + elements.dropFirst()
        }
    )
  )
  .take(closeBraceParser)
  .map { openBrace, head, tail, inKeyword, body, closeBrace -> SyntaxNode<Closure<EmptyAnnotation>> in
    let parameters: [Closure<EmptyAnnotation>.Parameter]
    if let tail = tail {
      let headWithOptionalCommas = head.map { id, comma -> (SyntaxNode<Identifier>, SyntaxNode<Empty>?) in
        (id, comma)
      }

      parameters = (headWithOptionalCommas + [(tail, nil)])
        .map { Closure.Parameter(identifier: $0.0, comma: $0.1) }
    } else {
      parameters = head.map { Closure.Parameter(identifier: $0.0, comma: $0.1) }
    }

    return Closure(
      openBrace: openBrace,
      parameters: parameters,
      inKeyword: inKeyword,
      body: body ?? [],
      closeBrace: closeBrace
    ).syntaxNode
  }

let closureParser = parametricClosureParser
  .orElse(nonParametricClosureParser)

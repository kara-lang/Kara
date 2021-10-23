//
//  Created by Max Desiatov on 16/08/2021.
//

import Parsing

public struct Closure {
  public typealias Body = [SyntaxNode<ExprBlock.Element>]

  public struct Parameter {
    public let identifier: SyntaxNode<Identifier>
    // FIXME: parse type annotations
    public let typeAnnotation: SyntaxNode<Expr>?
    public let comma: SyntaxNode<Empty>?
  }

  public let openBrace: SyntaxNode<Empty>
  public let parameters: [Parameter]
  public let inKeyword: SyntaxNode<Empty>?
  public let body: Body

  public let closeBrace: SyntaxNode<Empty>

  public var exprBlock: ExprBlock {
    .init(openBrace: openBrace, elements: body, closeBrace: closeBrace)
  }
}

extension Closure.Parameter {
  init(identifier: SyntaxNode<Identifier>, comma: SyntaxNode<Empty>?) {
    self.init(identifier: identifier, typeAnnotation: nil, comma: comma)
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
        .map { trivia, elements -> Closure.Body in
          [.init(leadingTrivia: trivia.map(\.content), content: elements[0].content)] + elements.dropFirst()
        }
    )
  )
  .take(closeBraceParser)
  .map { openBrace, head, tail, inKeyword, body, closeBrace -> SyntaxNode<Closure> in
    let parameters: [Closure.Parameter]
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

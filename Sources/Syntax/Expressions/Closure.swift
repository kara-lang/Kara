//
//  Created by Max Desiatov on 16/08/2021.
//

import Parsing

public struct Closure {
  public struct Parameter {
    public let identifier: SyntaxNode<Identifier>
    public let typeAnnotation: SyntaxNode<Type>?
  }

  public let openBrace: SyntaxNode<Empty>
  // FIXME: use a form of `DelimitedSequence` here?
  public let parameters: [Parameter]
  public let inKeyword: SyntaxNode<Empty>?
  public let body: SyntaxNode<Expr>?

  public let closeBrace: SyntaxNode<Empty>
}

extension Closure.Parameter {
  init(identifier: SyntaxNode<Identifier>) {
    self.init(identifier: identifier, typeAnnotation: nil)
  }
}

extension Closure: SyntaxNodeContainer {
  var start: SyntaxNode<Empty> { openBrace }
  var end: SyntaxNode<Empty> { closeBrace }
}

// FIXME: it's an awful hack, but it should work
extension Closure: Equatable {
  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.start == rhs.start && lhs.end == rhs.end
  }
}

extension Closure: CustomStringConvertible {
  public var description: String {
    let bodyString: String
    if let body = body?.content.content {
      bodyString = String(describing: body)
    } else {
      bodyString = ""
    }

    if parameters.isEmpty {
      return "{ \(bodyString) }"
    } else {
      return """
      { \(
        parameters.map(\.identifier.content.content.value)
          .joined(separator: ", ")
      ) in \(bodyString) }
      """
    }
  }
}

private extension Parser where Input == ParsingState {
  // FIXME: uses of this should be replaced with `SyntaxNodeParser`
  func skipWithWhitespace<P>(
    _ parser: P
  ) -> Parsers.SkipSecond<Parsers.SkipSecond<Self, LineCounter>, P> where P: Parser {
    skip(statefulWhitespace())
      .skip(parser)
  }
}

let closureParser =
  openBraceParser
    .take(
      Optional.parser(
        // Parses closures of form `{ a, b, c, in }`, note the trailing comma
        of: Many(
          identifierParser
            // FIXME: use `SyntaxNodeParser` here instead
            .skipWithWhitespace(commaParser)
            .skip(statefulWhitespace())
        )
        // Optional tail component without the comma to parse closures of form `{ a, b, c in }`
        .take(
          Optional.parser(of: identifierParser)
        )
        .skip(statefulWhitespace(isRequired: true))
        .take(SyntaxNodeParser(Terminal("in")))
        .skip(statefulWhitespace(isRequired: true))
        .map { head, tail, inKeyword -> ([Closure.Parameter], SyntaxNode<Empty>) in
          guard let tail = tail else {
            return (
              head
                .map { Closure.Parameter(identifier: $0) },
              inKeyword
            )
          }

          return (
            (head + [tail])
              .map { Closure.Parameter(identifier: $0) },
            inKeyword
          )
        }
      )
    )
    .take(
      Optional.parser(
        of: Lazy {
          exprParser
        }
      )
    )
    .take(closeBraceParser)
    .map { openBrace, params, body, closeBrace in
      Closure(
        openBrace: openBrace,
        parameters: params?.0 ?? [],
        inKeyword: params?.1,
        body: body,
        closeBrace: closeBrace
      ).syntaxNode
    }

//
//  Created by Max Desiatov on 16/08/2021.
//

import Parsing

public struct Closure {
  public struct Parameter {
    public let identifier: SyntaxNode<Identifier>
    public let typeAnnotation: SyntaxNode<Type>?
  }

  // FIXME: use a form of `DelimitedSequence` here?
  public let parameters: [Parameter]
  public let inKeyword: SyntaxNode<()>?
  public let body: SyntaxNode<Expr>?
}

extension Closure.Parameter {
  init(identifier: SyntaxNode<Identifier>) {
    self.init(identifier: identifier, typeAnnotation: nil)
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

let closureParser =
  openBraceParser
    .takeSkippingWhitespace(
      Optional.parser(
        // Parses closures of form `{ a, b, c, in }`, note the trailing comma
        of: Many(
          identifierParser
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
        .map { head, tail, inKeyword -> ([Closure.Parameter], SyntaxNode<()>) in
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
    .skip(statefulWhitespace())
    .take(closeBraceParser)
    .map { openBrace, params, body, closeBrace in
      SyntaxNode(
        leadingTrivia: openBrace.leadingTrivia,
        content: SourceRange(
          start: openBrace.content.start,
          end: closeBrace.content.end,
          content: Closure(
            parameters: params?.0 ?? [],
            inKeyword: params?.1,
            body: body
          )
        )
      )
    }

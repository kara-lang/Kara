//
//  Created by Max Desiatov on 16/08/2021.
//

import Parsing

public struct Closure {
  public struct Parameter {
    public let identifier: SourceRange<Identifier>
    let typeAnnotation: SourceRange<Type>?
  }

  public let parameters: [Parameter]
  public let body: SourceRange<Expr>?
}

extension Closure.Parameter {
  init(identifier: SourceRange<Identifier>) {
    self.init(identifier: identifier, typeAnnotation: nil)
  }
}

extension Closure: CustomDebugStringConvertible {
  public var debugDescription: String {
    let bodyString = body?.element.debugDescription ?? ""
    if parameters.isEmpty {
      return "{ \(bodyString) }"
    } else {
      return """
      { \(
        parameters.map(\.identifier.element.value)
          .joined(separator: ", ")
      ) in \(bodyString) }
      """
    }
  }
}

let closureParser =
  openBraceParser
    .skip(StatefulWhitespace())
    .take(
      Optional.parser(
        // Parses applications of form `f(a, b, c,)`, note the trailing comman
        of: Many(
          identifierParser
            .skip(StatefulWhitespace())
            .skip(commaParser)
            .skip(StatefulWhitespace())
        )
        // Optional tail component without the comma to parse applications of form `f(a, b, c)`
        .take(
          Optional.parser(of: identifierParser)
        )
        .skip(StatefulWhitespace(isRequired: true))
        .skip(Terminal("in"))
        .skip(StatefulWhitespace(isRequired: true))
        .map { head, tail -> [Closure.Parameter] in
          guard let tail = tail else {
            return head
              .map { Closure.Parameter(identifier: $0) }
          }

          return (head + [tail])
            .map { Closure.Parameter(identifier: $0) }
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
    .skip(StatefulWhitespace())
    .take(closeBraceParser)
    .map { openBrace, params, body, closeBrace in
      SourceRange(
        start: openBrace.start,
        end: closeBrace.end,
        element: Closure(
          parameters: params ?? [],
          body: body
        )
      )
    }

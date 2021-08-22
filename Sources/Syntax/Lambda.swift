//
//  Created by Max Desiatov on 16/08/2021.
//

import Parsing

public struct Lambda: Equatable {
  public struct Parameter: Equatable {
    public let identifier: SourceRange<Identifier>
    let typeAnnotation: SourceRange<Type>?
  }

  public let parameters: [Parameter]
  public let body: SourceRange<Expr>?
}

extension Lambda.Parameter {
  init(identifier: SourceRange<Identifier>) {
    self.init(identifier: identifier, typeAnnotation: nil)
  }
}

extension Lambda: CustomDebugStringConvertible {
  public var debugDescription: String {
    """
    { \(parameters.map(\.identifier.element.value).joined(separator: ", ")) in \(body?.element.debugDescription ?? "") }
    """
  }
}

let lambdaParser =
  openBraceParser
    .skip(StatefulWhitespace())
    .take(
      Optional.parser(
        of: Many(
          identifierParser
            .skip(StatefulWhitespace())
            .skip(commaParser)
            .skip(StatefulWhitespace())
        )
        .take(
          Optional.parser(of: identifierParser)
        )
        .skip(StatefulWhitespace(isRequired: true))
        .skip(Terminal("in"))
        .skip(StatefulWhitespace(isRequired: true))
        .map { head, tail -> [Lambda.Parameter] in
          guard let tail = tail else {
            return head
              .map { Lambda.Parameter(identifier: $0) }
          }

          return (head + [tail])
            .map { Lambda.Parameter(identifier: $0) }
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
        element: Lambda(
          parameters: params ?? [],
          body: body
        )
      )
    }

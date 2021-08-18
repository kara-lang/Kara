//
//  Created by Max Desiatov on 16/08/2021.
//

import Parsing

public struct Lambda: Equatable {
  init(identifiers: [Identifier] = [], body: Expr) {
    parameters = identifiers.map { Parameter(identifier: $0, typeAnnotation: nil) }
    self.body = body
  }

  public struct Parameter: Equatable {
    public let identifier: Identifier
    let typeAnnotation: Type?
  }

  public let parameters: [Parameter]
  public let body: Expr
}

extension Lambda: CustomDebugStringConvertible {
  public var debugDescription: String {
    "{ \(parameters.map(\.identifier.value).joined(separator: ", ")) in \(body.debugDescription) }"
  }
}

// let lambdaParser =
//  openBraceParser
//    .skip(Whitespace())
//    .take(
//      Optional.parser(
//        of: Many(
//          identifierParser
//            .skip(Whitespace())
//            .skip(commaParser)
//            .skip(Whitespace())
//        )
//        .take(
//          Optional.parser(of: identifierParser)
//        )
//        .skip(requiredWhitespaceParser)
//        .skip(UTF8Terminal("in".utf8))
//        .skip(requiredWhitespaceParser)
//        .map { head, tail -> [Identifier] in
//          guard let tail = tail else {
//            return head
//          }
//
//          return head + [tail]
//        }
//      )
//    )
//    .take(
//      Optional.parser(
//        of: Lazy {
//          exprParser
//        }
//      )
//    )
//    .skip(Whitespace())
//    .skip(closeBraceParser)
//    .map { Lambda(identifiers: $0 ?? [], body: $1 ?? .unit) }

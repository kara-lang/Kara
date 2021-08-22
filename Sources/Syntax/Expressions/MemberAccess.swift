//
//  Created by Max Desiatov on 22/08/2021.
//

import Parsing

public struct MemberAccess {
  public let base: Expr
  public let member: Identifier
}

let memberAccessParser =
  StatefulWhitespace()
    .ignoreOutput()
    .skip(
      Terminal(".")
    )
    .take(identifierParser)
    .map(ExprTail.memberAccess)

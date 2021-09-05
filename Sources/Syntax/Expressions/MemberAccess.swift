//
//  Created by Max Desiatov on 22/08/2021.
//

import Parsing

public struct MemberAccess {
  public let base: SourceRange<Expr>
  public let member: SourceRange<Identifier>
}

let memberAccessParser =
  StatefulWhitespace()
    .ignoreOutput()
    .skip(
      Terminal(".")
    )
    .take(identifierParser)
    .map(ExprSyntaxTail.memberAccess)

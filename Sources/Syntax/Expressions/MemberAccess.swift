//
//  Created by Max Desiatov on 22/08/2021.
//

import Parsing

public struct MemberAccess {
  public let base: SyntaxNode<Expr>
  public let dot: SyntaxNode<Empty>
  public let member: SyntaxNode<Identifier>
}

let memberAccessParser =
  SyntaxNodeParser(
    Terminal(".")
  )
  .take(identifierParser)
  .map(ExprSyntaxTail.memberAccess)

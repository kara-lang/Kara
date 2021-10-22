//
//  Created by Max Desiatov on 22/08/2021.
//

import Parsing

public struct MemberAccess {
  public enum Member: Equatable {
    case tupleElement(Int)
    case identifier(Identifier)
  }

  public let base: SyntaxNode<Expr>
  public let dot: SyntaxNode<Empty>
  public let member: SyntaxNode<Member>
}

let memberAccessParser =
  SyntaxNodeParser(
    Terminal(".")
  )
  .take(
    identifierParser().map { $0.map(MemberAccess.Member.identifier) }
      .orElse(SyntaxNodeParser(Int.parser().stateful()).map { $0.map(MemberAccess.Member.tupleElement) })
  )
  .map(ExprSyntaxTail.memberAccess)

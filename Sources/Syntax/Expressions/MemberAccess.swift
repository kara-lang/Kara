//
//  Created by Max Desiatov on 22/08/2021.
//

import Parsing

public enum Member: Hashable {
  case tupleElement(Int)
  case identifier(Identifier)
}

public struct MemberAccess<A: Annotation> {
  public let base: SyntaxNode<Expr<A>>
  public let dot: SyntaxNode<Empty>
  public let member: SyntaxNode<Member>

  public func addAnnotation<NewAnnotation>(
    _ transform: (Expr<A>) throws -> Expr<NewAnnotation>
  ) rethrows -> MemberAccess<NewAnnotation> {
    try .init(
      base: base.map(transform),
      dot: dot,
      member: member
    )
  }
}

let memberAccessParser =
  dotParser
    .take(
      identifierParser().map { $0.map(Member.identifier) }
        .orElse(SyntaxNodeParser(Int.parser().stateful()).map { $0.map(Member.tupleElement) })
    )
    .map(ExprSyntaxTail.memberAccess)

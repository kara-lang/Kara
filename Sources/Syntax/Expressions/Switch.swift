//
//  Created by Max Desiatov on 04/11/2021.
//

struct Switch<A: Annotation> {
  public struct CaseBlock {
    public let pattern: CasePattern<A>
    public let colon: SyntaxNode<Empty>
  }

  public let switchKeyword: SyntaxNode<Empty>
  public let subject: SyntaxNode<Expr<A>>
}

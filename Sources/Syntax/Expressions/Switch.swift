//
//  Created by Max Desiatov on 04/11/2021.
//

import Parsing

struct Switch<A: Annotation> {
  public struct CaseBlock {
    public typealias Body = [SyntaxNode<ExprBlock<A>.Element>]
    public let pattern: CasePattern<A>
    public let colon: SyntaxNode<Empty>
    public let body: Body
  }

  public let switchKeyword: SyntaxNode<Empty>
  public let subject: SyntaxNode<Expr<A>>
  public let openBrace: SyntaxNode<Empty>
  public let caseBlocks: [CaseBlock]
  public let closeBrace: SyntaxNode<Empty>
}

private let caseBlockParser =
  casePatternParser
    .take(colonParser)
    .take(exprBlockElementsParser)
    .map(Switch<EmptyAnnotation>.CaseBlock.init)

let switchParser =
  Keyword.switch.parser
    .take(exprParser)
    .take(openBraceParser)
    .take(Many(caseBlockParser))
    .take(closeBraceParser)
    .map(Switch.init)

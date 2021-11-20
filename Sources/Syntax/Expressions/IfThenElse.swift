//
//  Created by Max Desiatov on 04/09/2021.
//

import Parsing

public struct IfThenElse<A: Annotation> {
  public struct ElseBranch {
    public let elseKeyword: SyntaxNode<Empty>
    public let elseBlock: ExprBlock<A>
  }

  public let ifKeyword: SyntaxNode<Empty>
  public let condition: SyntaxNode<Expr<A>>
  public let thenBlock: ExprBlock<A>

  // FIXME: handle multiple `else if` branches
  public let elseBranch: ElseBranch?

  public func addAnnotation<NewAnnotation>(
    condition conditionTransform: (Expr<A>) throws -> Expr<NewAnnotation>,
    thenBlock thenBlockTransform: (ExprBlock<A>) throws -> ExprBlock<NewAnnotation>,
    elseBlock elseBlockTransform: (ExprBlock<A>) throws -> ExprBlock<NewAnnotation>
  ) rethrows -> IfThenElse<NewAnnotation> {
    try .init(
      ifKeyword: ifKeyword,
      condition: condition.map(conditionTransform),
      thenBlock: thenBlockTransform(thenBlock),
      elseBranch: elseBranch.map {
        try .init(
          elseKeyword: $0.elseKeyword,
          elseBlock: elseBlockTransform($0.elseBlock)
        )
      }
    )
  }
}

private let elseBranchParser = Keyword.else.parser
  .take(Lazy { exprBlockParser })
  .map {
    IfThenElse<EmptyAnnotation>.ElseBranch(
      elseKeyword: $0,
      elseBlock: $1.content.content
    )
  }

let ifThenElseParser = Keyword.if.parser
  .take(Lazy { exprParser() })
  .take(Lazy { exprBlockParser })
  .take(Optional.parser(of: elseBranchParser))
  .map { tuple -> SyntaxNode<IfThenElse<EmptyAnnotation>> in
    let (ifKeyword, condition, thenBlock, elseBranch) = tuple
    return SyntaxNode(
      leadingTrivia: ifKeyword.leadingTrivia,
      content: SourceRange(
        start: ifKeyword.content.start,
        end: elseBranch?.elseBlock.closeBrace.content.end ?? thenBlock.closeBrace.content.end,
        content: IfThenElse(
          ifKeyword: ifKeyword,
          condition: condition,
          thenBlock: thenBlock.content.content,
          elseBranch: elseBranch
        )
      )
    )
  }

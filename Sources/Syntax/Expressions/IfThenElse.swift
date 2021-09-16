//
//  Created by Max Desiatov on 04/09/2021.
//

import Parsing

public struct IfThenElse {
  public let ifKeyword: SyntaxNode<()>
  public let condition: SyntaxNode<Expr>
  public let thenOpenBrace: SyntaxNode<()>
  public let thenBody: SyntaxNode<Expr>
  public let thenCloseBrace: SyntaxNode<()>

  // FIXME: make optional, also handle multiple `else if` branches
  public let elseBranch: ElseBranch
}

public struct ElseBranch {
  public let elseKeyword: SyntaxNode<()>
  public let elseOpenBrace: SyntaxNode<()>
  public let elseBody: SyntaxNode<Expr>
  public let elseCloseBrace: SyntaxNode<()>
}

private let elseBranchParser = SyntaxNodeParser(Terminal("else"))
  .take(SyntaxNodeParser(openBraceParser))
  .take(Lazy { exprParser })
  .take(SyntaxNodeParser(closeBraceParser))
  .map {
    ElseBranch(
      elseKeyword: $0,
      elseOpenBrace: $1,
      elseBody: $2,
      elseCloseBrace: $3
    )
  }

let ifThenElseParser = SyntaxNodeParser(Terminal("if"))
  .take(Lazy { exprParser })
  .take(SyntaxNodeParser(openBraceParser))
  .take(Lazy { exprParser })
  .take(SyntaxNodeParser(closeBraceParser))
  .take(elseBranchParser)
  .map { tuple -> SyntaxNode<IfThenElse> in
    let (ifKeyword, condition, thenOpenBrace, thenBody, thenCloseBrace, elseBranch) = tuple
    return SyntaxNode(
      leadingTrivia: ifKeyword.leadingTrivia,
      content: SourceRange(
        start: ifKeyword.content.start,
        end: elseBranch.elseCloseBrace.content.end,
        content: IfThenElse(
          ifKeyword: ifKeyword,
          condition: condition,
          thenOpenBrace: thenOpenBrace,
          thenBody: thenBody,
          thenCloseBrace: thenCloseBrace,
          elseBranch: elseBranch
        )
      )
    )
  }

//
//  Created by Max Desiatov on 04/09/2021.
//

import Parsing

public struct IfThenElse {
  public let condition: SyntaxNode<Expr>
  public let thenBranch: SyntaxNode<Expr>
  public let elseBranch: SyntaxNode<Expr>
}

let ifThenElseParser = Terminal("if")
  .takeSkippingWhitespace(Lazy { exprParser })
  .skipWithWhitespace(openBraceParser)
  .takeSkippingWhitespace(Lazy { exprParser })
  .skipWithWhitespace(closeBraceParser)
  .skipWithWhitespace(Terminal("else"))
  .skipWithWhitespace(openBraceParser)
  .takeSkippingWhitespace(Lazy { exprParser })
  .takeSkippingWhitespace(closeBraceParser)
  .map { ifToken, condition, thenBranch, elseBranch, closeBrace in
    SourceRange(
      start: ifToken.start,
      end: closeBrace.end,
      content: IfThenElse(
        condition: condition,
        thenBranch: thenBranch,
        elseBranch: elseBranch
      )
    )
  }

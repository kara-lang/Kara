//
//  Created by Max Desiatov on 11/08/2021.
//

import Parsing

struct BindingDecl {
  let identifier: SyntaxNode<Identifier>
  let value: SyntaxNode<Expr>
}

let bindingParser = SyntaxNodeParser(Terminal("let"))
  .take(SyntaxNodeParser(identifierParser))
  .skipWithWhitespace(Terminal("="))
  .take(SyntaxNodeParser(exprParser))
  .map { letNode, identifierNode, exprNode in
    SyntaxNode(
      leadingTrivia: letNode.leadingTrivia,
      content: SourceRange(
        start: letNode.content.start,
        end: exprNode.content.end,
        content: BindingDecl(
          identifier: identifierNode,
          value: exprNode
        )
      )
    )
  }

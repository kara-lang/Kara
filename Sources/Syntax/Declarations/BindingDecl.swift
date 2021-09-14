//
//  Created by Max Desiatov on 11/08/2021.
//

import Parsing

struct BindingDecl {
  let identifier: SyntaxNode<Identifier>
  let equalsSign: SyntaxNode<()>
  let value: SyntaxNode<Expr>
}

let bindingParser = SyntaxNodeParser(Terminal("let"))
  .take(SyntaxNodeParser(identifierParser))
  .take(SyntaxNodeParser(Terminal("=")))
  .take(exprParser)
  .map { letNode, identifierNode, equalsSignNode, exprNode in
    SyntaxNode(
      leadingTrivia: letNode.leadingTrivia,
      content: SourceRange(
        start: letNode.content.start,
        end: exprNode.content.end,
        content: BindingDecl(
          identifier: identifierNode,
          equalsSign: equalsSignNode,
          value: exprNode
        )
      )
    )
  }

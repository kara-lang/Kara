//
//  Created by Max Desiatov on 11/08/2021.
//

import Parsing

public struct BindingDecl {
  public let bindingKeyword: SyntaxNode<()>
  public let identifier: SyntaxNode<Identifier>
  public let equalsSign: SyntaxNode<()>
  public let value: SyntaxNode<Expr>
}

extension BindingDecl: CustomStringConvertible {
  public var description: String {
    "let \(identifier.description) = \(value.description)"
  }
}

let bindingParser = SyntaxNodeParser(Terminal("let"))
  .take(identifierParser)
  .take(SyntaxNodeParser(Terminal("=")))
  .take(exprParser)
  .map { letNode, identifierNode, equalsSignNode, exprNode in
    SyntaxNode(
      leadingTrivia: letNode.leadingTrivia,
      content: SourceRange(
        start: letNode.content.start,
        end: exprNode.content.end,
        content: BindingDecl(
          bindingKeyword: letNode,
          identifier: identifierNode,
          equalsSign: equalsSignNode,
          value: exprNode
        )
      )
    )
  }

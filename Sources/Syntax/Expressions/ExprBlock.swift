//
//  Created by Max Desiatov on 21/09/2021.
//

import Parsing

public struct ExprBlock {
  public enum Element {
    case expr(Expr)
    case declaration(Declaration)
  }

  public let openBrace: SyntaxNode<Empty>
  public var elements: [SyntaxNode<Element>]
  public let closeBrace: SyntaxNode<Empty>
}

extension ExprBlock: SyntaxNodeContainer {
  public var start: SyntaxNode<Empty> { openBrace }
  public var end: SyntaxNode<Empty> { closeBrace }
}

let exprBlockElementsParser = Many(
  OneOf {
    Lazy { declarationParser }.map { $0.map(ExprBlock.Element.declaration) }
    Lazy { exprParser }.map { $0.map(ExprBlock.Element.expr) }
  },
  separator: newlineParser
)

let exprBlockParser = Parse {
  openBraceParser
  exprBlockElementsParser
  closeBraceParser
}
.map(ExprBlock.init)
.map(\.syntaxNode)

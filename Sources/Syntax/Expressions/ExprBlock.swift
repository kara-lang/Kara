//
//  Created by Max Desiatov on 21/09/2021.
//

import Parsing

public struct ExprBlock {
  public enum Element {
    case expr(Expr)
    case binding(BindingDecl)
  }

  public let openBrace: SyntaxNode<()>
  public var elements: [SyntaxNode<Element>]
  public let closeBrace: SyntaxNode<()>

  public var sourceRange: SourceRange<()> {
    .init(start: openBrace.content.start, end: closeBrace.content.end, content: ())
  }
}

let exprBlockParser = openBraceParser
  .take(
    Many(
      // FIXME: require separation by a newline
      exprParser.map { $0.map(ExprBlock.Element.expr) }
        .orElse(bindingParser.map { $0.map(ExprBlock.Element.binding) })
    )
  )
  .take(closeBraceParser)
  .map(ExprBlock.init)

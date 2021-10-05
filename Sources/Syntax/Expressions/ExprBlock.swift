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
  public let elements: [SyntaxNode<Element>]
  public let closeBrace: SyntaxNode<()>

  public var sourceRange: SourceRange<()> {
    .init(start: openBrace.content.start, end: closeBrace.content.end, content: ())
  }
}

extension ExprBlock.Element: CustomStringConvertible {
  public var description: String {
    switch self {
    case let .expr(e):
      return e.description
    case let .binding(b):
      return b.description
    }
  }
}

extension ExprBlock: CustomStringConvertible {
  public var description: String {
    """
    {
      \(elements.map(\.content.content.description).joined(separator: "\n"))
    }
    """
  }
}

let exprBlockParser = SyntaxNodeParser(openBraceParser)
  .take(
    Many(
      // FIXME: require separation by a newline
      exprParser.map { $0.map(ExprBlock.Element.expr) }
        .orElse(bindingParser.map { $0.map(ExprBlock.Element.binding) })
    )
  )
  .take(SyntaxNodeParser(closeBraceParser))
  .map(ExprBlock.init)

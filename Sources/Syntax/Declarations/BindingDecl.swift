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

extension BindingDecl: SyntaxNodeContainer {
  var start: SyntaxNode<()> {
    bindingKeyword
  }

  var end: SyntaxNode<()> {
    value.map { _ in }
  }
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
  .map(BindingDecl.init)
  .map(\.syntaxNode)

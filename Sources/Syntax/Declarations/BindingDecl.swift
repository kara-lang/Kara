//
//  Created by Max Desiatov on 11/08/2021.
//

import Parsing

public struct BindingDecl {
  public struct TypeAnnotation {
    public let colon: SyntaxNode<()>
    public let signature: SyntaxNode<Type>
  }

  public struct Value {
    public let equalsSign: SyntaxNode<()>
    public let expr: SyntaxNode<Expr>
  }

  public let bindingKeyword: SyntaxNode<()>
  public let identifier: SyntaxNode<Identifier>
  public let typeAnnotation: TypeAnnotation?
  public let value: Value?
}

extension BindingDecl: SyntaxNodeContainer {
  var start: SyntaxNode<()> {
    bindingKeyword
  }

  var end: SyntaxNode<()> {
    value?.expr.map { _ in } ?? identifier.map { _ in }
  }
}

let bindingParser = SyntaxNodeParser(Terminal("let"))
  .take(identifierParser)
  .take(
    Optional.parser(
      of: colonParser
        .take(typeParser)
        .map(BindingDecl.TypeAnnotation.init)
    )
  )
  .take(
    Optional.parser(
      of: SyntaxNodeParser(Terminal("="))
        .take(exprParser)
        .map(BindingDecl.Value.init)
    )
  )
  .map(BindingDecl.init)
  .map(\.syntaxNode)

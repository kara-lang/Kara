//
//  Created by Max Desiatov on 11/08/2021.
//

import Parsing

public struct BindingDecl: ModifiersContainer {
  public struct TypeAnnotation {
    public let colon: SyntaxNode<Empty>
    public let signature: SyntaxNode<Expr>
  }

  public struct Value {
    public let equalsSign: SyntaxNode<Empty>
    public let expr: SyntaxNode<Expr>
  }

  public let modifiers: [SyntaxNode<DeclModifier>]
  public let bindingKeyword: SyntaxNode<Empty>
  public let identifier: SyntaxNode<Identifier>
  public let typeAnnotation: TypeAnnotation?
  public let value: Value?
}

extension BindingDecl: SyntaxNodeContainer {
  public var start: SyntaxNode<Empty> { bindingKeyword }
  public var end: SyntaxNode<Empty> { value?.expr.empty ?? identifier.empty }
}

let bindingParser = Parse {
  Many(declModifierParser)

  Keyword.let.parser
  identifierParser()

  Optional.parser(
    of: colonParser
      .take(exprParser)
      .map(BindingDecl.TypeAnnotation.init)
  )

  Optional.parser(
    of: SyntaxNodeParser(Terminal("="))
      .take(exprParser)
      .map(BindingDecl.Value.init)
  )
}
.map(BindingDecl.init)
.map(\.syntaxNode)

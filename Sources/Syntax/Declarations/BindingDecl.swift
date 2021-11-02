//
//  Created by Max Desiatov on 11/08/2021.
//

import Parsing

public struct BindingDecl<A: Annotation>: ModifiersContainer {
  public struct TypeSignature {
    public let colon: SyntaxNode<Empty>
    public let signature: SyntaxNode<Expr<A>>
  }

  public struct Value {
    public let equalsSign: SyntaxNode<Empty>
    public let expr: SyntaxNode<Expr<A>>
  }

  public let modifiers: [SyntaxNode<DeclModifier>]
  public let bindingKeyword: SyntaxNode<Empty>
  public let identifier: SyntaxNode<Identifier>
  public let typeSignature: TypeSignature?
  public let value: Value?

  public func addAnnotation<NewAnnotation: Annotation>(
    typeSignature typeSignatureTransform: (Expr<A>) throws -> Expr<NewAnnotation>,
    value valueTransform: (Expr<A>) throws -> Expr<NewAnnotation>
  ) rethrows -> BindingDecl<NewAnnotation> {
    try .init(
      modifiers: modifiers,
      bindingKeyword: bindingKeyword,
      identifier: identifier,
      typeSignature: typeSignature.map {
        try .init(
          colon: $0.colon,
          signature: $0.signature.map(typeSignatureTransform)
        )
      },
      value: value.map {
        try .init(
          equalsSign: $0.equalsSign,
          expr: $0.expr.map(valueTransform)
        )
      }
    )
  }
}

extension BindingDecl: SyntaxNodeContainer {
  public var start: SyntaxNode<Empty> { bindingKeyword }
  public var end: SyntaxNode<Empty> { value?.expr.empty ?? identifier.empty }
}

let bindingParser = Many(declModifierParser)
  .take(Keyword.let.parser)
  .take(identifierParser())
  .take(
    Optional.parser(
      of: colonParser
        .take(exprParser)
        .map(BindingDecl.TypeSignature.init)
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

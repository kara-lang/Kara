//
//  Created by Max Desiatov on 07/06/2019.
//

import Parsing

public struct FuncDecl<A: Annotation>: ModifiersContainer {
  public struct Parameter {
    public let externalName: SyntaxNode<Identifier>?
    public let internalName: SyntaxNode<Identifier>
    public let colon: SyntaxNode<Empty>
    public let type: SyntaxNode<Expr<A>>

    public func addAnnotation<NewAnnotation: Annotation>(
      _ transform: (Expr<A>) throws -> Expr<NewAnnotation>
    ) rethrows -> FuncDecl<NewAnnotation>.Parameter {
      try .init(
        externalName: externalName,
        internalName: internalName,
        colon: colon,
        type: type.map { try transform($0) }
      )
    }
  }

  public struct Arrow: SyntaxNodeContainer {
    public let arrowSymbol: SyntaxNode<Empty>
    public let returns: SyntaxNode<Expr<A>>

    public var start: SyntaxNode<Empty> { arrowSymbol }
    public var end: SyntaxNode<Empty> { returns.empty }
  }

  public let modifiers: [SyntaxNode<DeclModifier>]
  public let funcKeyword: SyntaxNode<Empty>
  public let identifier: SyntaxNode<Identifier>
  public let parameters: DelimitedSequence<Parameter>

  public let arrow: Arrow?
  public var body: ExprBlock<A>?

  public func addAnnotation<NewAnnotation: Annotation>(
    parameterType parameterTypeTransform: (Expr<A>) throws -> Expr<NewAnnotation>,
    arrow arrowTransform: (Expr<A>) throws -> Expr<NewAnnotation>,
    body bodyTransform: (ExprBlock<A>) throws -> ExprBlock<NewAnnotation>
  ) rethrows -> FuncDecl<NewAnnotation> {
    try .init(
      modifiers: modifiers,
      funcKeyword: funcKeyword,
      identifier: identifier,
      parameters: parameters.map {
        try .init(
          externalName: $0.externalName,
          internalName: $0.internalName,
          colon: $0.colon,
          type: $0.type.map(parameterTypeTransform)
        )
      },
      arrow: arrow.map {
        try .init(
          arrowSymbol: $0.arrowSymbol,
          returns: $0.returns.map(arrowTransform)
        )
      },
      body: body.map(bodyTransform)
    )
  }
}

extension FuncDecl: SyntaxNodeContainer {
  public var start: SyntaxNode<Empty> { modifiers.first?.empty ?? funcKeyword }
  public var end: SyntaxNode<Empty> { body?.closeBrace ?? arrow?.returns.map { _ in
    Empty()
  } ?? parameters.end }
}

let functionParameterParser = identifierParser()
  .take(Optional.parser(of: identifierParser(requiresLeadingTrivia: true)))
  .take(colonParser)
  .take(exprParser())
  .map { firstName, secondName, colon, type in
    SyntaxNode(
      leadingTrivia: firstName.leadingTrivia,
      content:
      SourceRange(
        start: firstName.content.start,
        end: type.content.end,
        content: FuncDecl.Parameter(
          externalName: secondName == nil ? nil : firstName,
          internalName: secondName == nil ? firstName : secondName!,
          colon: colon,
          type: type
        )
      )
    )
  }

let funcDeclParser =
  Many(declModifierParser)
    .take(Keyword.func.parser)
    .take(identifierParser(requiresLeadingTrivia: true))
    .take(
      delimitedSequenceParser(
        startParser: openParenParser,
        endParser: closeParenParser,
        separatorParser: commaParser,
        elementParser: functionParameterParser
      )
    )
    .take(Optional.parser(of: arrowTailParser.map(FuncDecl.Arrow.init)))
    .take(Optional.parser(of: exprBlockParser))
    .map {
      FuncDecl(
        modifiers: $0,
        funcKeyword: $1,
        identifier: $2,
        // FIXME: fix generic parameters parsing
        parameters: $3,
        arrow: $4,
        body: $5?.content.content
      ).syntaxNode
    }

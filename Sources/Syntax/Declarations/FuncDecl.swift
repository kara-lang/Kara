//
//  Created by Max Desiatov on 07/06/2019.
//

import Parsing

public struct FuncDecl: ModifiersContainer {
  public struct Parameter {
    public let externalName: SyntaxNode<Identifier>?
    public let internalName: SyntaxNode<Identifier>
    public let colon: SyntaxNode<Empty>
    public let type: SyntaxNode<Expr>
  }

  public struct Arrow: SyntaxNodeContainer {
    public let arrowSymbol: SyntaxNode<Empty>
    public let returns: SyntaxNode<Expr>

    public var start: SyntaxNode<Empty> { arrowSymbol }
    public var end: SyntaxNode<Empty> { returns.empty }
  }

  public let modifiers: [SyntaxNode<DeclModifier>]
  public let funcKeyword: SyntaxNode<Empty>
  public let identifier: SyntaxNode<Identifier>
  public let parameters: DelimitedSequence<Parameter>

  public let arrow: SyntaxNode<Arrow>?
  public var body: ExprBlock?
}

extension FuncDecl: SyntaxNodeContainer {
  public var start: SyntaxNode<Empty> { modifiers.first?.empty ?? funcKeyword }
  public var end: SyntaxNode<Empty> { body?.closeBrace ?? arrow?.map(\.returns).map { _ in
    Empty()
  } ?? parameters.end }
}

let functionParameterParser = identifierParser()
  .take(Optional.parser(of: identifierParser(requiresLeadingTrivia: true)))
  .take(colonParser)
  .take(exprParser)
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
    .take(Optional.parser(of: arrowTailParser.map(FuncDecl.Arrow.init).map(\.syntaxNode)))
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

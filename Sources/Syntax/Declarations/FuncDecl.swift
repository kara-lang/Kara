//
//  Created by Max Desiatov on 07/06/2019.
//

import Parsing

public struct FuncDecl: ModifiersContainer {
  public struct Parameter: SyntaxNodeContainer {
    public let externalName: SyntaxNode<Identifier>?
    public let internalName: SyntaxNode<Identifier>
    public let colon: SyntaxNode<Empty>
    public let type: SyntaxNode<Expr>

    public var start: SyntaxNode<Empty> { externalName?.empty ?? internalName.empty }
    public var end: SyntaxNode<Empty> { type.empty }
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

let functionParameterParser = Parse {
  identifierParser()
  Optional.parser(of: identifierParser(requiresLeadingTrivia: true))
  colonParser
  exprParser
}
.map { firstName, secondName, colon, type in
  FuncDecl.Parameter(
    externalName: secondName == nil ? nil : firstName,
    internalName: secondName == nil ? firstName : secondName!,
    colon: colon,
    type: type
  ).syntaxNode
}

let funcDeclParser = Parse {
  Many(declModifierParser)
  Keyword.func.parser
  identifierParser(requiresLeadingTrivia: true)

  delimitedSequenceParser(
    startParser: openParenParser,
    endParser: closeParenParser,
    separatorParser: commaParser,
    elementParser: functionParameterParser
  )
  Optional.parser(of: arrowTailParser.map(FuncDecl.Arrow.init).map(\.syntaxNode))
  Optional.parser(of: exprBlockParser.map(\.content.content))
}
.map(FuncDecl.init)
.map(\.syntaxNode)

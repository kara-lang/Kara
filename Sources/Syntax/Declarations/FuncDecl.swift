//
//  Created by Max Desiatov on 07/06/2019.
//

import Parsing

public struct FuncDecl {
  public struct Parameter {
    public let externalName: SyntaxNode<Identifier>?
    public let internalName: SyntaxNode<Identifier>
    public let colon: SyntaxNode<()>
    public let type: SyntaxNode<Type>
  }

  public let modifiers: [SyntaxNode<DeclModifier>]
  public let funcKeyword: SyntaxNode<()>
  public let identifier: SyntaxNode<Identifier>
  public let genericParameters: [TypeVariable]
  public let parameters: DelimitedSequence<Parameter>

  public let returns: SyntaxNode<Type>?
  public var body: ExprBlock?
}

extension FuncDecl: SyntaxNodeContainer {
  var start: SyntaxNode<()> {
    modifiers.first?.map { _ in } ?? funcKeyword
  }

  var end: SyntaxNode<()> {
    body?.closeBrace ?? returns?.map { _ in } ?? parameters.end
  }
}

let functionParameterParser = identifierParser
  .take(Optional.parser(of: identifierParser))
  .take(colonParser)
  .take(typeParser)
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
    .take(SyntaxNodeParser(Terminal("func")))
    .take(identifierParser)
    .take(
      delimitedSequenceParser(
        startParser: openParenParser,
        endParser: closeParenParser,
        elementParser: functionParameterParser
      )
    )
    .take(Optional.parser(of: arrowParser))
    .take(Optional.parser(of: exprBlockParser))
    .map {
      FuncDecl(
        modifiers: $0,
        funcKeyword: $1,
        identifier: $2,
        // FIXME: fix generic parameters parsing
        genericParameters: [],
        parameters: $3,
        returns: $4,
        body: $5
      ).syntaxNode
    }

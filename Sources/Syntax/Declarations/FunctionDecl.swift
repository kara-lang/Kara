//
//  Created by Max Desiatov on 07/06/2019.
//

import Parsing

public struct FunctionDecl {
  public struct Parameter {
    public let externalName: SyntaxNode<Identifier>?
    public let internalName: SyntaxNode<Identifier>
    public let colon: SyntaxNode<()>
    public let type: SyntaxNode<Type>
  }

  public let funcKeyword: SyntaxNode<()>
  public let identifier: SyntaxNode<Identifier>
  public let genericParameters: [TypeVariable]
  public let parameters: DelimitedSequence<Parameter>

  public let returns: SyntaxNode<Type>?
  public let openBrace: SyntaxNode<()>
  public let body: SyntaxNode<Expr>?
  public let closeBrace: SyntaxNode<()>
}

extension FunctionDecl: CustomStringConvertible {
  public var description: String {
    """
    func \(identifier.content.content.value)(\(
      parameters.elementsContent.map {
        """
        \($0.externalName?.content.content.value ?? "")\(
          $0.externalName == nil ? "" : " "
        )\($0.internalName.content.content.value): \($0.type.content)
        """
      }.joined(separator: ", ")
    )) -> \(returns?.description ?? "()") {
      \(body?.content.content ?? "")
    }
    """
  }
}

let functionParameterParser = identifierParser
  .take(Optional.parser(of: identifierParser))
  .take(SyntaxNodeParser(Terminal(":")))
  .take(typeParser)
  .map { firstName, secondName, colon, type in
    SyntaxNode(
      leadingTrivia: firstName.leadingTrivia,
      content:
      SourceRange(
        start: firstName.content.start,
        end: type.content.end,
        content: FunctionDecl.Parameter(
          externalName: secondName == nil ? nil : firstName,
          internalName: secondName == nil ? firstName : secondName!,
          colon: colon,
          type: type
        )
      )
    )
  }

let functionDeclParser = SyntaxNodeParser(Terminal("func"))
  .take(identifierParser)
  .take(
    delimitedSequenceParser(
      startParser: openParenParser,
      endParser: closeParenParser,
      elementParser: functionParameterParser
    ).debug()
  )
  .take(
    Optional.parser(of: arrowParser)
  )
  .take(SyntaxNodeParser(openBraceParser.debug()))
  .take(exprParser.debug())
  .take(SyntaxNodeParser(closeBraceParser))
  .map { funcKeyword, identifier, parameters, returns, openBrace, body, closeBrace in
    SyntaxNode(
      leadingTrivia: funcKeyword.leadingTrivia,
      content: SourceRange(
        start: funcKeyword.content.start,
        end: closeBrace.content.end,
        content: FunctionDecl(
          funcKeyword: funcKeyword,
          identifier: identifier,
          // FIXME: fix generic parameters parsing
          genericParameters: [],
          parameters: parameters,
          returns: returns,
          openBrace: openBrace,
          body: body,
          closeBrace: closeBrace
        )
      )
    )
  }

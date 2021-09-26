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

  public let funcKeyword: SyntaxNode<()>
  public let identifier: SyntaxNode<Identifier>
  public let genericParameters: [TypeVariable]
  public let parameters: DelimitedSequence<Parameter>

  public let returns: SyntaxNode<Type>?
  public let body: ExprBlock?
}

extension FuncDecl: CustomStringConvertible {
  public var description: String {
    let bodyTail: String
    if let body = body {
      bodyTail = " \(body.description)"
    } else {
      bodyTail = ""
    }

    return """
    func \(identifier.content.content.value)(\(
      parameters.elementsContent.map {
        """
        \($0.externalName?.content.content.value ?? "")\(
          $0.externalName == nil ? "" : " "
        )\($0.internalName.content.content.value): \($0.type.content)
        """
      }.joined(separator: ", ")
    )) -> \(returns?.description ?? "()")\(bodyTail)
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
        content: FuncDecl.Parameter(
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
  .take(Optional.parser(of: arrowParser))
  .take(Optional.parser(of: exprBlockParser))
  .map { funcKeyword, identifier, parameters, returns, exprBlock in
    SyntaxNode(
      leadingTrivia: funcKeyword.leadingTrivia,
      content: SourceRange(
        start: funcKeyword.content.start,
        end: exprBlock?.closeBrace.content.end ?? returns?.content.end ?? parameters.end.content.end,
        content: FuncDecl(
          funcKeyword: funcKeyword,
          identifier: identifier,
          // FIXME: fix generic parameters parsing
          genericParameters: [],
          parameters: parameters,
          returns: returns,
          body: exprBlock
        )
      )
    )
  }

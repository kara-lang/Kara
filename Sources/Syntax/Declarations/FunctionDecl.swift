//
//  Created by Max Desiatov on 07/06/2019.
//

import Parsing

public struct FunctionDecl {
  public struct Parameter {
    public let externalName: SourceRange<Identifier>?
    public let internalName: SourceRange<Identifier>
    public let type: SourceRange<Type>
  }

  public let genericParameters: [TypeVariable]
  public let parameters: [Parameter]
  public let body: SourceRange<Expr>
  public let returns: SourceRange<Type>
}

let functionParameterParser = identifierParser
  .takeSkippingWhitespace(Optional.parser(of: identifierParser))
  .skipWithWhitespace(Terminal(":"))

let functionDeclParser = Terminal("func")
  .takeSkippingWhitespace(identifierParser)
  .skipWithWhitespace(openParenParser)
  .skipWithWhitespace(closeParenParser)
  .skipWithWhitespace(openBraceParser)
  .takeSkippingWhitespace(exprParser)
  .skipWithWhitespace(closeBraceParser)

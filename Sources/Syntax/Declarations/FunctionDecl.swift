//
//  Created by Max Desiatov on 07/06/2019.
//

import Parsing

public struct FunctionDecl {
  public let genericParameters: [TypeVariable]
  public let parameters: [(externalName: String?, internalName: String, typeAnnotation: Type)]
  let body: Expr
  public let returns: Type
}

let functionDeclParser = Terminal("func")
  .takeSkippingWhitespace(identifierParser)
  .skipWithWhitespace(openParenParser)
  .skipWithWhitespace(closeParenParser)
  .skipWithWhitespace(openBraceParser)
  .skipWithWhitespace(closeBraceParser)

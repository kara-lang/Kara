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
  .skip(StatefulWhitespace())
  .take(identifierParser)
  .skip(StatefulWhitespace())
  .skip(openParenParser)
  .skip(StatefulWhitespace())
  .skip(closeParenParser)
  .skip(StatefulWhitespace())
  .skip(openBraceParser)
  .skip(StatefulWhitespace())
  .skip(closeBraceParser)

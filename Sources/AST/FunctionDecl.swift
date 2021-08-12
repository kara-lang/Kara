//
//  Created by Max Desiatov on 07/06/2019.
//

import Parsing

public struct FunctionDecl {
  public let genericParameters: [TypeVariable]
  public let parameters: [(externalName: String?, internalName: String?, typeAnnotation: Type)]
  let statements: [Statement]
  public let returns: Type?
}

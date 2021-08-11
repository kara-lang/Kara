//
//  Created by Max Desiatov on 10/08/2021.
//

struct File {
  let statements: [Statement]
}

public struct Identifier: Hashable {
  public let value: String
}

enum Statement {
  case binding(Identifier, Expr)
}

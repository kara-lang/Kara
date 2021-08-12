//
//  Created by Max Desiatov on 10/08/2021.
//

import Parsing

struct File {
  let statements: [Statement]
}

enum Statement {
  case binding(Identifier, Expr)
}

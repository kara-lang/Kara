//
//  Created by Max Desiatov on 13/08/2021.
//

import Parsing

public struct Tuple: Equatable {
  public struct Element: Equatable {
    public let name: Identifier?
    public let expr: Expr
  }

  public let elements: [Element]
}

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

let tupleSequenceParser = openParenParser
  .skip(Whitespace())
  .take(
    Many(
      exprParser
        .skip(Whitespace())
        .skip(commaParser)
        .skip(Whitespace())
    )
  )
  .skip(Whitespace())
  .skip(closeParenParser)

let tupleParser = tupleSequenceParser
  .map(Expr.tuple)

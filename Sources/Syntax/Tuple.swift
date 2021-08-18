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

public extension Tuple {
  init(_ expressions: [Expr] = []) {
    self.init(elements: expressions.map {
      .init(name: nil, expr: $0)
    })
  }
}

let tupleSequenceParser = openParenParser
  .skip(Whitespace())
  .take(
    Many(
      Lazy { exprParser }
        .skip(Whitespace())
        .skip(commaParser)
        .skip(Whitespace())
    )
  )
  .take(Optional.parser(of: Lazy { exprParser }))
  .skip(Whitespace())
  .skip(closeParenParser)
  .map { head, tail -> [Expr] in
    guard let tail = tail else {
      return head
    }

    return head + [tail]
  }

let tupleParser = tupleSequenceParser
  .map(Tuple.init)

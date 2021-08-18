//
//  Created by Max Desiatov on 13/08/2021.
//

import Parsing

public struct Tuple: Equatable {
  public struct Element: Equatable {
    // FIXME: temporary internal initializer for XCTest. Remove when proper end-to-end test suite is established.
    init(name: Identifier?, expr: Expr) {
      let dummy = ""
      self.name = name.map { SourceLocation(range: dummy.startIndex...dummy.endIndex, element: $0) }
      self.expr = SourceLocation(range: dummy.startIndex...dummy.endIndex, element: expr)
    }

    public let name: SourceLocation<Identifier>?
    public let expr: SourceLocation<Expr>
  }

  public let elements: [Element]
}

extension Tuple {
  // FIXME: temporary internal initializer for XCTest. Remove when proper end-to-end test suite is established.
  init(_ expressions: [Expr] = []) {
    self.init(elements: expressions.map {
      .init(name: nil, expr: $0)
    })
  }
}

// let tupleSequenceParser = openParenParser
//  .skip(Whitespace())
//  .take(
//    Many(
//      Lazy { exprParser }
//        .skip(Whitespace())
//        .skip(commaParser)
//        .skip(Whitespace())
//    )
//  )
//  .take(Optional.parser(of: Lazy { exprParser }))
//  .skip(Whitespace())
//  .skip(closeParenParser)
//  .map { head, tail -> [Expr] in
//    guard let tail = tail else {
//      return head
//    }
//
//    return head + [tail]
//  }
//
// let tupleParser = tupleSequenceParser
//  .map(Tuple.init)

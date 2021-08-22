//
//  Created by Max Desiatov on 13/08/2021.
//

import Parsing

public struct Tuple {
  public struct Element {
    public let name: SourceRange<Identifier>?
    public let expr: SourceRange<Expr>
  }

  public let elements: [Element]
}

extension Tuple.Element {
  init(_ expr: SourceRange<Expr>) {
    self.init(name: nil, expr: expr)
  }
}

let tupleSequenceParser = openParenParser
  .skip(StatefulWhitespace())
  .take(
    Many(
      Lazy { exprParser }
        .skip(StatefulWhitespace())
        .skip(commaParser)
        .skip(StatefulWhitespace())
    )
  )
  .take(Optional.parser(of: Lazy { exprParser }))
  .skip(StatefulWhitespace())
  .take(closeParenParser)
  .map { openParen, head, tail, closeParen -> SourceRange<[SourceRange<Expr>]> in
    guard let tail = tail else {
      return SourceRange(start: openParen.start, end: closeParen.end, element: head)
    }

    return SourceRange(start: openParen.start, end: closeParen.end, element: head + [tail])
  }

let tupleParser = tupleSequenceParser
  .map {
    SourceRange(
      start: $0.start,
      end: $0.end,
      element: Tuple(elements: $0.element.map { .init(name: nil, expr: $0) })
    )
  }

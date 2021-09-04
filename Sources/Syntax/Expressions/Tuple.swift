//
//  Created by Max Desiatov on 13/08/2021.
//

import Parsing

public struct Tuple<T> {
  public let elements: [SourceRange<T>]
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
      element: Tuple(elements: $0.element)
    )
  }

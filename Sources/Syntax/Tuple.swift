//
//  Created by Max Desiatov on 13/08/2021.
//

import Parsing

public struct Tuple: Equatable {
  public struct Element: Equatable {
    public let name: SourceRange<Identifier>?
    public let expr: SourceRange<Expr>
  }

  public let elements: [Element]
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
    let completeRange = openParen.range.lowerBound...closeParen.range.upperBound

    guard let tail = tail else {
      return SourceRange(range: completeRange, element: head)
    }

    return SourceRange(range: completeRange, element: head + [tail])
  }

let tupleParser = tupleSequenceParser
  .map {
    SourceRange(
      range: $0.range,
      element: Tuple(elements: $0.element.map { .init(name: nil, expr: $0) })
    )
  }

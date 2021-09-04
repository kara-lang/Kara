//
//  Created by Max Desiatov on 13/08/2021.
//

import Parsing

public struct Tuple<T> {
  public let elements: [SourceRange<T>]
}

func tupleSequenceParser<T>(
  elementParser: Lazy<AnyParser<ParsingState, SourceRange<T>>>
) -> AnyParser<ParsingState, SourceRange<[SourceRange<T>]>> {
  openParenParser
    .skip(StatefulWhitespace())
    .take(
      Many(
        elementParser
          .skip(StatefulWhitespace())
          .skip(commaParser)
          .skip(StatefulWhitespace())
      )
    )
    .take(Optional.parser(of: elementParser))
    .skip(StatefulWhitespace())
    .take(closeParenParser)
    .map { openParen, head, tail, closeParen -> SourceRange<[SourceRange<T>]> in
      guard let tail = tail else {
        return SourceRange(start: openParen.start, end: closeParen.end, element: head)
      }

      return SourceRange(start: openParen.start, end: closeParen.end, element: head + [tail])
    }
    .eraseToAnyParser()
}

let tupleExprParser = tupleSequenceParser(elementParser: Lazy { exprParser })
  .map {
    SourceRange(
      start: $0.start,
      end: $0.end,
      element: Tuple(elements: $0.element)
    )
  }

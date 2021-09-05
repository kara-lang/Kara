//
//  Created by Max Desiatov on 13/08/2021.
//

import Parsing

public struct Tuple<T> {
  public let elements: [SourceRange<T>]
}

func delimitedSequenceParser<T>(
  startParser: Terminal,
  endParser: Terminal,
  elementParser: Lazy<AnyParser<ParsingState, SourceRange<T>>>,
  atLeast minimum: Int = 0
) -> AnyParser<ParsingState, SourceRange<[SourceRange<T>]>> {
  startParser
    .takeSkippingWhitespace(
      Many(
        elementParser
          .skipWithWhitespace(commaParser)
          .skip(StatefulWhitespace())
      )
    )
    .take(Optional.parser(of: elementParser))
    .takeSkippingWhitespace(endParser)
    .compactMap { startToken, head, tail, endToken -> SourceRange<[SourceRange<T>]>? in
      guard let tail = tail else {
        guard head.count >= minimum else { return nil }

        return SourceRange(start: startToken.start, end: endToken.end, element: head)
      }

      let result = head + [tail]

      guard result.count >= minimum else { return nil }

      return SourceRange(start: startToken.start, end: endToken.end, element: head + [tail])
    }
    .eraseToAnyParser()
}

let tupleExprParser = delimitedSequenceParser(
  startParser: openParenParser,
  endParser: closeParenParser,
  elementParser: Lazy { exprParser }
)
.map {
  SourceRange(
    start: $0.start,
    end: $0.end,
    element: Tuple(elements: $0.element)
  )
}

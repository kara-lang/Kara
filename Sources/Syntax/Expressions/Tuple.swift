//
//  Created by Max Desiatov on 13/08/2021.
//

import Parsing

public struct Tuple<T> {
  public let elements: [SyntaxNode<T>]
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
    content: Tuple(elements: $0.content)
  )
}

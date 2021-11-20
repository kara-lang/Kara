//
//  Created by Max Desiatov on 13/08/2021.
//

import Parsing

let tupleExprParser = delimitedSequenceParser(
  startParser: openParenParser,
  endParser: closeParenParser,
  separatorParser: commaParser,
  elementParser: Lazy { exprParser() }
)

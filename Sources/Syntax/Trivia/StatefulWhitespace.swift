//
//  Created by Max Desiatov on 19/08/2021.
//

import Parsing

func statefulWhitespace(isRequired: Bool, consumesNewline: Bool) -> LineCounter {
  LineCounter(isRequired: isRequired, consumesNewline: consumesNewline, lookaheadAmount: 1) {
    $0.first == .init(ascii: " ")
  }
}

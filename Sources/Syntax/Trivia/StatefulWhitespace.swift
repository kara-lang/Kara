//
//  Created by Max Desiatov on 19/08/2021.
//

import Parsing

func statefulWhitespace(isRequired: Bool = false) -> LineCounter {
  LineCounter(isRequired: isRequired, lookaheadAmount: 1) {
    $0.first == .init(ascii: " ")
  }
}

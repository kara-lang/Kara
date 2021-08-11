//
//  Created by Max Desiatov on 10/08/2021.
//

import Parsing

struct ParsingContext {
  let source: String
  var currentIndex: String.Index
  var currentCharacter = 0
  var currentLine = 0
}

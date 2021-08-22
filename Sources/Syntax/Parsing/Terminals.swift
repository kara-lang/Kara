//
//  Created by Max Desiatov on 19/08/2021.
//

import Parsing

struct Terminal: Parser {
  init(_ string: String) {
    self.string = string
  }

  let string: String

  func parse(_ state: inout ParsingState) -> SourceRange<()>? {
    StartsWith(string.utf8).stateful().parse(&state)
  }
}

typealias UTF8SubSequence = String.UTF8View.SubSequence
typealias UTF8Terminal = StartsWith<UTF8SubSequence>

let newlineAndWhitespace = [UInt8(ascii: " "), UInt8(ascii: "\n"), UInt8(ascii: "\r")]

let openBraceParser = Terminal("{")
let closeBraceParser = Terminal("}")

let openParenParser = Terminal("(")
let closeParenParser = Terminal(")")

let commaParser = Terminal(",")

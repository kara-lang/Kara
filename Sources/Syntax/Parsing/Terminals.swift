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

public typealias UTF8SubSequence = String.UTF8View.SubSequence
typealias UTF8Terminal = StartsWith<UTF8SubSequence>

let newlineCodeUnits = [UInt8(ascii: "\n"), UInt8(ascii: "\r")]
let whitespaceCodeUnits = newlineCodeUnits + [UInt8(ascii: " ")]

let openBraceParser = Terminal("{")
let closeBraceParser = Terminal("}")

let openParenParser = Terminal("(")
let closeParenParser = Terminal(")")

let openAngleBracketParser = Terminal("<")
let closeAngleBracketParser = Terminal(">")

let commaParser = Terminal(",")

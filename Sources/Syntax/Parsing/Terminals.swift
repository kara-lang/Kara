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

// FIXME: these should be wrapped in `SyntaxNodeParser`, or maybe `Terminal` should do that in the first place.
let openBraceParser = SyntaxNodeParser(Terminal("{"))
let closeBraceParser = SyntaxNodeParser(Terminal("}"))

let openParenParser = SyntaxNodeParser(Terminal("("))
let closeParenParser = SyntaxNodeParser(Terminal(")"))

let openAngleBracketParser = SyntaxNodeParser(Terminal("<"))
let closeAngleBracketParser = SyntaxNodeParser(Terminal(">"))

let openSquareBracketParser = SyntaxNodeParser(Terminal("["))
let closeSquareBracketParser = SyntaxNodeParser(Terminal("]"))

let colonParser = SyntaxNodeParser(Terminal(":"))

let commaParser = Terminal(",")

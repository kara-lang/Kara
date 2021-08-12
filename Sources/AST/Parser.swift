//
//  Created by Max Desiatov on 10/08/2021.
//

import Parsing

struct ParsingState {
  let source: String
  var currentIndex: String.UTF8View.Index
  var currentCharacter = 0
  var currentLine = 0
}

struct StatefulParser<P: Parser>: Parser where P.Input == Substring.UTF8View {
  let inner: P

  func parse(_ state: inout ParsingState) -> SourceLocation<P.Output>? {
    let start = state.currentIndex

    var substring = state.source.utf8[state.currentIndex...]
    guard let output = inner.parse(&substring) else {
      return nil
    }

    state.currentIndex = substring.startIndex

    return SourceLocation(
      start: start,
      end: state.source.index(before: state.currentIndex),
      element: output
    )
  }
}

extension Parser where Input == Substring.UTF8View {
  func stateful() -> StatefulParser<Self> {
    .init(inner: self)
  }
}

typealias UTF8Subsequence = String.UTF8View.SubSequence
typealias UTF8Terminal = StartsWith<UTF8Subsequence>

let newlineAndWhitespace = [UInt8(ascii: " "), UInt8(ascii: "\n"), UInt8(ascii: "\r")]

let whitespaceParser = Whitespace<UTF8Subsequence>()
let requiredWhitespaceParser = OneOfMany(
  newlineAndWhitespace
    .compactMap { String(bytes: [$0], encoding: .utf8) }
    .map { StartsWith<UTF8Subsequence>($0.utf8) }
)

let openingBraceParser = UTF8Terminal("{".utf8)
let closingBraceParser = UTF8Terminal("}".utf8)

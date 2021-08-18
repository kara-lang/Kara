//
//  Created by Max Desiatov on 10/08/2021.
//

import Parsing

struct ParsingState {
  let source: String
  var currentIndex: String.UTF8View.Index
  var currentColumn = 0
  var currentLine = 0
}

struct StatefulParser<P: Parser>: Parser where P.Input == UTF8SubSequence {
  let inner: P

  func parse(_ state: inout ParsingState) -> SourceLocation<P.Output>? {
    let start = state.currentIndex

    var substring = state.source.utf8[state.currentIndex...]
    let initialCount = substring.count

    guard let output = inner.parse(&substring) else {
      return nil
    }

    state.currentIndex = substring.startIndex
    state.currentColumn += initialCount - substring.count

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

struct Lookahead<Upstream: Parser>: Parser where Upstream.Input: Collection {
  let upstream: Upstream
  let amount: Int
  let validator: (Input.SubSequence) -> Bool

  func parse(_ input: inout Upstream.Input) -> Upstream.Output? {
    let oldInput = input
    let output = upstream.parse(&input)

    guard let output = output, validator(input.prefix(amount)) else {
      input = oldInput
      return nil
    }

    return output
  }
}

extension Parser where Input: Collection {
  func lookahead(amount: Int,
                 _ validator: @escaping (Input.SubSequence) -> Bool) -> Lookahead<Self>
  {
    Lookahead(upstream: self, amount: amount, validator: validator)
  }
}

struct Debug<Upstream: Parser>: Parser {
  let upstream: Upstream

  func parse(_ input: inout Upstream.Input) -> Upstream.Output? {
    print("Input before parsing: \(input)")

    let output = upstream.parse(&input)

    print("Input after parsing: \(input)")
    print("Parsing output: \(String(describing: output))")

    return output
  }
}

extension Parser {
  func debug() -> Debug<Self> {
    Debug(upstream: self)
  }
}

typealias UTF8SubSequence = String.UTF8View.SubSequence
typealias UTF8Terminal = StartsWith<UTF8SubSequence>

let newlineAndWhitespace = [UInt8(ascii: " "), UInt8(ascii: "\n"), UInt8(ascii: "\r")]

let whitespaceParser = Whitespace<UTF8SubSequence>()
let requiredWhitespaceParser = OneOfMany(
  newlineAndWhitespace
    .compactMap { String(bytes: [$0], encoding: .utf8) }
    .map { StartsWith<UTF8SubSequence>($0.utf8) }
)

let openBraceParser = UTF8Terminal("{".utf8)
let closeBraceParser = UTF8Terminal("}".utf8)

let openParenParser = UTF8Terminal("(".utf8)
let closeParenParser = UTF8Terminal(")".utf8)

let commaParser = UTF8Terminal(",".utf8)

//
//  Created by Max Desiatov on 10/09/2021.
//

import Parsing

struct LineCounter: Parser {
  /// Whether this parser is required to consume at least one code unit.
  let isRequired: Bool
  /// Whether this parser consumes newline symbols.
  let consumesNewline: Bool
  let lookaheadAmount: Int
  let lookahead: (UTF8SubSequence) -> Bool
  init(isRequired: Bool, consumesNewline: Bool, lookaheadAmount: Int,
       lookahead: @escaping (UTF8SubSequence) -> Bool)
  {
    self.isRequired = isRequired
    self.consumesNewline = consumesNewline
    self.lookaheadAmount = lookaheadAmount
    self.lookahead = lookahead
  }

  func parse(_ state: inout ParsingState) -> SourceRange<UTF8SubSequence>? {
    let substring = state.source.utf8[state.index...]

    var nextIndex = state.index

    // Used to avoid counting Windows `\r\n` newlines as two separate lines.
    var isCarriageReturn = false

    let oldState = state

    loop: while nextIndex != substring.endIndex {
      let lookaheadResult = lookahead(state.source.utf8[nextIndex...].prefix(lookaheadAmount))
      switch (consumesNewline, lookaheadResult, substring[nextIndex]) {
      case (true, _, .init(ascii: "\r")):
        state.column += 1
        isCarriageReturn = true

      case (true, _, .init(ascii: "\n")):
        state.nextLine()
        isCarriageReturn = false

      case (_, true, _), (_, _, .init(ascii: "\t")):
        if isCarriageReturn {
          state.nextLine()
        } else {
          state.column += 1
        }

        isCarriageReturn = false

      default:
        // Simple break without a label only exits the `switch` statement.
        break loop
      }

      nextIndex = substring.index(after: nextIndex)
    }

    if isCarriageReturn {
      state.column = 0
      state.line += 1
    }

    state.index = nextIndex

    if isRequired && nextIndex == oldState.index {
      return nil
    } else {
      return SourceRange(
        start: oldState.sourceLocation,
        end: state.sourceLocation,
        content: state.source.utf8[oldState.index..<nextIndex]
      )
    }
  }
}

let newlineParser = LineCounter(isRequired: true, consumesNewline: true, lookaheadAmount: 0, lookahead: { _ in false })

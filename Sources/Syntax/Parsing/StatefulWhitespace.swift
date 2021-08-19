//
//  Created by Max Desiatov on 19/08/2021.
//

import Parsing

struct StatefulWhitespace: Parser {
  init(isRequired: Bool = false) {
    self.isRequired = isRequired
  }

  /// Whether this parser is required to consume at least one whitespace symbol.
  let isRequired: Bool

  func parse(_ state: inout ParsingState) -> ()? {
    let substring = state.source.utf8[state.currentIndex...]

    var nextIndex = state.currentIndex

    // Used to avoid counting Windows `\r\n` newlines as two separate lines.
    var isCarriageReturn = false

    defer {
      if isCarriageReturn {
        state.currentColumn = 0
        state.currentLine += 1
      }

      state.currentIndex = nextIndex
    }

    loop: while nextIndex != substring.endIndex {
      switch substring[nextIndex] {
      case .init(ascii: "\r"):
        state.currentColumn += 1
        isCarriageReturn = true

      case .init(ascii: "\n"):
        state.currentColumn = 0
        state.currentLine += 1
        isCarriageReturn = false

      case .init(ascii: " "), .init(ascii: "\t"):
        if isCarriageReturn {
          state.currentColumn = 0
          state.currentLine += 1
        } else {
          state.currentColumn += 1
        }

        isCarriageReturn = false

      default:
        // Simple break without a label only exits the `switch` statement.
        break loop
      }

      nextIndex = substring.index(after: nextIndex)
    }

    if isRequired && nextIndex == state.currentIndex {
      return nil
    } else {
      return ()
    }
  }
}

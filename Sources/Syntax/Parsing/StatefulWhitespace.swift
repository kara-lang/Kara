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

extension Parser where Input == ParsingState {
  func skipWithWhitespace<P>(
    _ parser: P
  ) -> Parsers.SkipSecond<Parsers.SkipSecond<Self, StatefulWhitespace>, P> where P: Parser {
    skip(StatefulWhitespace())
      .skip(parser)
  }

  func takeSkippingWhitespace<P>(
    _ parser: P
  ) -> Parsers.Take2<Parsers.SkipSecond<Self, StatefulWhitespace>, P>
    where P: Parser, Self.Input == P.Input
  {
    skip(StatefulWhitespace())
      .take(parser)
  }

  func takeSkippingWhitespace<A, B, P>(
    _ parser: P
  ) -> Parsers.Take3<Parsers.SkipSecond<Self, StatefulWhitespace>, A, B, P>
    where P: Parser, Self.Input == P.Input, Self.Output == (A, B)
  {
    skip(StatefulWhitespace())
      .take(parser)
  }

  // swiftlint:disable large_tuple
  func takeSkippingWhitespace<A, B, C, P>(
    _ parser: P
  ) -> Parsers.Take4<Parsers.SkipSecond<Self, StatefulWhitespace>, A, B, C, P>
    where P: Parser, Self.Input == P.Input, Self.Output == (A, B, C)
  {
    skip(StatefulWhitespace())
      .take(parser)
  }

  func takeSkippingWhitespace<A, B, C, D, P>(
    _ parser: P
  ) -> Parsers.Take5<Parsers.SkipSecond<Self, StatefulWhitespace>, A, B, C, D, P>
    where P: Parser, Self.Input == P.Input, Self.Output == (A, B, C, D)
  {
    skip(StatefulWhitespace())
      .take(parser)
  }

  func takeSkippingWhitespace<A, B, C, D, E, P>(
    _ parser: P
  ) -> Parsers.Take6<Parsers.SkipSecond<Self, StatefulWhitespace>, A, B, C, D, E, P>
    where P: Parser, Self.Input == P.Input, Self.Output == (A, B, C, D, E)
  {
    skip(StatefulWhitespace())
      .take(parser)
  }
}

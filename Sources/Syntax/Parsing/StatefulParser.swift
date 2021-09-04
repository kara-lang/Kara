//
//  Created by Max Desiatov on 10/08/2021.
//

import Parsing

public struct ParsingState: Equatable {
  let source: String
  var currentIndex: String.UTF8View.Index
  var currentColumn = 0
  var currentLine = 0
}

public extension ParsingState {
  init(source: String) {
    self.source = source
    currentIndex = source.startIndex
  }
}

extension ParsingState: ExpressibleByStringLiteral {
  public init(stringLiteral value: String) {
    self.init(source: value)
  }
}

extension ParsingState: CustomDebugStringConvertible {
  public var debugDescription: String {
    String(source[currentIndex...])
  }
}

struct StatefulParser<P: Parser>: Parser where P.Input == UTF8SubSequence {
  let inner: P

  func parse(_ state: inout ParsingState) -> SourceRange<P.Output>? {
    let startColumn = state.currentColumn
    let startLine = state.currentLine

    var substring = state.source.utf8[state.currentIndex...]
    let initialCount = substring.count

    guard let output = inner.parse(&substring) else {
      return nil
    }

    state.currentIndex = substring.startIndex
    state.currentColumn += initialCount - substring.count

    return SourceRange(
      start: .init(column: startColumn, line: startLine),
      end: .init(
        column: state.currentColumn - 1,
        line: state.currentLine
      ),
      element: output
    )
  }
}

extension Parser where Input == Substring.UTF8View {
  func stateful() -> StatefulParser<Self> {
    .init(inner: self)
  }
}

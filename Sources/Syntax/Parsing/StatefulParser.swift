//
//  Created by Max Desiatov on 10/08/2021.
//

import Parsing

public struct ParsingState: Equatable {
  let source: String
  var index: String.UTF8View.Index
  var column = 0
  var line = 0

  mutating func nextLine() {
    column = 0
    line += 1
  }

  var sourceLocation: SourceLocation {
    .init(column: column, line: line, filePath: nil)
  }
}

public extension ParsingState {
  init(source: String) {
    self.source = source
    index = source.startIndex
  }
}

extension ParsingState: ExpressibleByStringLiteral {
  public init(stringLiteral value: String) {
    self.init(source: value)
  }
}

extension ParsingState: CustomDebugStringConvertible {
  public var debugDescription: String {
    String(source[index...])
  }
}

struct StatefulParser<P: Parser>: Parser where P.Input == UTF8SubSequence {
  let inner: P

  func parse(_ state: inout ParsingState) -> SourceRange<P.Output>? {
    let startColumn = state.column
    let startLine = state.line

    var substring = state.source.utf8[state.index...]
    let initialCount = substring.count

    guard let output = inner.parse(&substring) else {
      return nil
    }

    state.index = substring.startIndex
    state.column += initialCount - substring.count

    return SourceRange(
      start: .init(column: startColumn, line: startLine),
      end: .init(
        column: state.column - 1,
        line: state.line
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

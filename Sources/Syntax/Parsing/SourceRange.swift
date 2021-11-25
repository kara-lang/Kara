//
//  Created by Max Desiatov on 10/08/2021.
//

import Parsing

public struct SourceLocation: Hashable {
  init(column: Int, line: Int) {
    self.column = column
    self.line = line
  }

  let column: Int
  let line: Int
}

/// Workaround for `()` not being `Hashable`.
public struct Empty: Hashable {}

public struct SourceRange<Content> {
  let start: SourceLocation
  let end: SourceLocation

  public let content: Content

  public func map<NewContent>(_ transform: (Content) throws -> NewContent) rethrows -> SourceRange<NewContent> {
    try .init(start: start, end: end, content: transform(content))
  }
}

extension SourceRange: Equatable where Content: Equatable {}

extension SourceRange: Hashable where Content: Hashable {}

extension SourceRange where Content == Empty {
  init(start: SourceLocation, end: SourceLocation) {
    self.start = start
    self.end = end
    content = Empty()
  }

  public func merge(_ other: Self) -> Self {
    .init(start: start, end: other.end)
  }
}

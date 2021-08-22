//
//  Created by Max Desiatov on 10/08/2021.
//

import Parsing

public struct SourceLocation: Equatable {
  init(column: Int, line: Int, filePath: String? = nil) {
    self.column = column
    self.line = line
    self.filePath = filePath
  }

  let column: Int
  let line: Int
  let filePath: String?
}

public struct SourceRange<Element> {
  let start: SourceLocation
  let end: SourceLocation

  public let element: Element
}

extension SourceRange: Equatable where Element: Equatable {}

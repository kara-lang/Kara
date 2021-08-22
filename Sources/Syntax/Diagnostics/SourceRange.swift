//
//  Created by Max Desiatov on 10/08/2021.
//

import Parsing

public struct SourceLocation {
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

  func map<NewElement>(_ transform: (Element) -> NewElement) -> SourceRange<NewElement> {
    .init(start: start, end: end, element: transform(element))
  }
}

extension SourceRange: CustomDebugStringConvertible {
  public var debugDescription: String {
    "\(start.line):\(start.column)-\(end.line):\(end.column) \(String(reflecting: element))"
  }
}

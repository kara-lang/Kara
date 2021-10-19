//
//  Created by Max Desiatov on 10/09/2021.
//

import CustomDump
import Parsing

public enum Trivia: Hashable {
  case comment(Comment)
  case whitespace(String)
}

extension Trivia: CustomDumpStringConvertible {
  public var customDumpDescription: String {
    switch self {
    case let .comment(content):
      var result = ""
      customDump(content, to: &result)
      return result
    case let .whitespace(content):
      return "Whitespace(\(String(Substring(content)).debugDescription))"
    }
  }
}

extension Trivia: CustomStringConvertible {
  public var description: String {
    switch self {
    case let .comment(content):
      return String(describing: content)
    case let .whitespace(content):
      return String(Substring(content))
    }
  }
}

let triviaParser = Many(
  commentParser
    .map { $0.map(Trivia.comment) }
    .orElse(
      statefulWhitespace(isRequired: true)
        .map { $0.map { Trivia.whitespace(String(Substring($0))) } }
    )
)

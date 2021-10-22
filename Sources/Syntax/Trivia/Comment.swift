//
//  Created by Max Desiatov on 09/09/2021.
//

import CustomDump
import Parsing

public struct Comment: Hashable {
  enum Kind {
    case singleLine
    case multipleLines
  }

  let kind: Kind
  let isDocComment: Bool
  let content: String
}

let singleLineCommentParser = Terminal("//")
  .take(Prefix { !newlineCodeUnits.contains($0) }.stateful())
  .map { delimiter, content -> SourceRange<Comment> in
    let isDocComment = content.content.first == UInt8(ascii: "/")
    return SourceRange(
      start: delimiter.start,
      end: content.end,
      content: Comment(
        kind: .singleLine,
        isDocComment: isDocComment,
        content: String(Substring(isDocComment ? content.content.dropFirst() : content.content))
      )
    )
  }

let multipleLinesCommentParser = Terminal("/*")
  .take(
    LineCounter(isRequired: true, lookaheadAmount: 2) {
      Array($0) != [UInt8(ascii: "*"), UInt8(ascii: "/")]
    }
  )
  .take(Terminal("*/"))
  .map { commentStart, content, commentEnd -> SourceRange<Comment> in
    let isDocComment = content.content.first == UInt8(ascii: "*")
    return SourceRange(
      start: commentStart.start,
      end: commentEnd.end,
      content: Comment(
        kind: .multipleLines,
        isDocComment: isDocComment,
        content: String(Substring(isDocComment ? content.content.dropFirst() : content.content))
      )
    )
  }

let commentParser = singleLineCommentParser.orElse(multipleLinesCommentParser)

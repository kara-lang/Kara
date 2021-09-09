//
//  Created by Max Desiatov on 09/09/2021.
//

import Parsing

struct Comment {
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
    let isDocComment = content.element.first == UInt8(ascii: "/")
    return SourceRange(
      start: delimiter.start,
      end: content.end,
      element: Comment(
        kind: .singleLine,
        isDocComment: isDocComment,
        content: String(Substring(isDocComment ? content.element.dropFirst() : content.element))
      )
    )
  }

let multipleLinesCommentParser = Terminal("/*")
  .take(PrefixUpTo("*/".utf8).stateful())
  .map { delimiter, content -> SourceRange<Comment> in
    let isDocComment = content.element.first == UInt8(ascii: "*")
    return SourceRange(
      start: delimiter.start,
      end: content.end,
      element: Comment(
        kind: .multipleLines,
        isDocComment: isDocComment,
        content: String(Substring(isDocComment ? content.element.dropFirst() : content.element))
      )
    )
  }

let commentsParser = singleLineCommentParser.orElse(multipleLinesCommentParser)

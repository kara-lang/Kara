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

typealias TriviaParser = Many<
  Parsers.OneOf<Parsers.Map<
    Parsers
      .OneOf<
        Parsers.Map<Parsers.Take2<Terminal, StatefulParser<Prefix<Substring.UTF8View>>>, SourceRange<Comment>>,
        Parsers.Map<
          Parsers
            .Take3<Parsers.Take2<Terminal, LineCounter>, SourceRange<Empty>, SourceRange<Substring.UTF8View>, Terminal>,
          SourceRange<Comment>
        >
      >,
    SourceRange<Trivia>
  >, Parsers.Map<LineCounter, SourceRange<Trivia>>>,
  [SourceRange<Trivia>],
  Always<ParsingState, ()>
>

func triviaParser(requiresLeadingTrivia: Bool, consumesNewline: Bool) -> TriviaParser {
  Many(
    commentParser
      .map { $0.map(Trivia.comment) }
      .orElse(
        statefulWhitespace(isRequired: true, consumesNewline: consumesNewline)
          .map { $0.map { Trivia.whitespace(String(Substring($0))) } }
      ),
    atLeast: requiresLeadingTrivia ? 1 : 0
  )
}

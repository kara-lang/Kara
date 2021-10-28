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
  OneOf<OneOf2<
    Parsers.Map<OneOf<OneOf2<
      Parsers.Map<Parse<Zip2_OO<Terminal, StatefulParser<Prefix<Substring.UTF8View>>>>, SourceRange<Comment>>,
      Parsers.Map<Parse<Zip3_OOO<Terminal, LineCounter, Terminal>>, SourceRange<Comment>>
    >>, SourceRange<Trivia>>,
    Parsers.Map<LineCounter, SourceRange<Trivia>>
  >>,
  [SourceRange<Trivia>],
  Always<ParsingState, ()>
>

func triviaParser(requiresLeadingTrivia: Bool) -> TriviaParser {
  let result = Many(
    OneOf {
      commentParser
        .map { $0.map(Trivia.comment) }

      statefulWhitespace(isRequired: true)
        .map { $0.map { Trivia.whitespace(String(Substring($0))) } }
    },
    atLeast: requiresLeadingTrivia ? 1 : 0
  )

  return result
}

//
//  Created by Max Desiatov on 10/09/2021.
//

import Parsing

public enum Trivia {
  case comment(Comment)
  case whitespace(UTF8SubSequence)
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
        .map { $0.map(Trivia.whitespace) }
    )
)

extension Parser where Input == ParsingState {
  func skipWithWhitespace<P>(
    _ parser: P
  ) -> Parsers.SkipSecond<Parsers.SkipSecond<Self, LineCounter>, P> where P: Parser {
    skip(statefulWhitespace())
      .skip(parser)
  }

  func takeSkippingWhitespace<P>(
    _ parser: P
  ) -> Parsers.Take2<Parsers.SkipSecond<Self, LineCounter>, P>
    where P: Parser, Self.Input == P.Input
  {
    skip(statefulWhitespace())
      .take(parser)
  }

  func takeSkippingWhitespace<A, B, P>(
    _ parser: P
  ) -> Parsers.Take3<Parsers.SkipSecond<Self, LineCounter>, A, B, P>
    where P: Parser, Self.Input == P.Input, Self.Output == (A, B)
  {
    skip(statefulWhitespace())
      .take(parser)
  }

  // swiftlint:disable large_tuple
  func takeSkippingWhitespace<A, B, C, P>(
    _ parser: P
  ) -> Parsers.Take4<Parsers.SkipSecond<Self, LineCounter>, A, B, C, P>
    where P: Parser, Self.Input == P.Input, Self.Output == (A, B, C)
  {
    skip(statefulWhitespace())
      .take(parser)
  }

  func takeSkippingWhitespace<A, B, C, D, P>(
    _ parser: P
  ) -> Parsers.Take5<Parsers.SkipSecond<Self, LineCounter>, A, B, C, D, P>
    where P: Parser, Self.Input == P.Input, Self.Output == (A, B, C, D)
  {
    skip(statefulWhitespace())
      .take(parser)
  }

  func takeSkippingWhitespace<A, B, C, D, E, P>(
    _ parser: P
  ) -> Parsers.Take6<Parsers.SkipSecond<Self, LineCounter>, A, B, C, D, E, P>
    where P: Parser, Self.Input == P.Input, Self.Output == (A, B, C, D, E)
  {
    skip(statefulWhitespace())
      .take(parser)
  }
}

//
//  Created by Max Desiatov on 10/09/2021.
//

import Parsing

public struct SyntaxNode<Content> {
  let leadingTrivia: [Trivia]
  public let content: SourceRange<Content>

  func map<NewContent>(_ transform: (Content) -> NewContent) -> SyntaxNode<NewContent> {
    .init(leadingTrivia: leadingTrivia, content: content.map(transform))
  }
}

extension SyntaxNode: CustomStringConvertible {
  public var description: String {
    "\(leadingTrivia.map(String.init(describing:)).joined())\(String(describing: content.content))"
  }
}

extension SyntaxNode: CustomDebugStringConvertible {
  public var debugDescription: String {
    """
    \(leadingTrivia
      .isEmpty ? "" : String(reflecting: leadingTrivia.map(String.init(reflecting:))))\(String(reflecting: content))
    """
  }
}

struct SyntaxNodeParser<Inner, Content>: Parser
  where Inner: Parser, Inner.Input == ParsingState, Inner.Output == SourceRange<Content>
{
  init(_ inner: Inner) {
    self.inner = inner
  }

  let inner: Inner

  func parse(_ input: inout ParsingState) -> SyntaxNode<Content>? {
    triviaParser
      .take(inner)
      .map { SyntaxNode(leadingTrivia: $0.map(\.content), content: $1) }
      .parse(&input)
  }
}

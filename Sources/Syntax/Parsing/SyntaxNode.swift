//
//  Created by Max Desiatov on 10/09/2021.
//

import Parsing

struct SyntaxNode<Content> {
  let leadingTrivia: [Trivia]
  let content: SourceRange<Content>

  func map<NewContent>(_ transform: (Content) -> NewContent) -> SyntaxNode<NewContent> {
    .init(leadingTrivia: leadingTrivia, content: content.map(transform))
  }
}

extension SyntaxNode: CustomStringConvertible {
  var description: String {
    "\(leadingTrivia.map(\.description).joined())\(String(describing: content.content))"
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
    Many(triviaParser)
      .take(inner)
      .map { SyntaxNode(leadingTrivia: $0.map(\.content), content: $1) }
      .parse(&input)
  }
}

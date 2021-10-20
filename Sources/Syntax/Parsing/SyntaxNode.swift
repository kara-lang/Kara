//
//  Created by Max Desiatov on 10/09/2021.
//

import Parsing

@dynamicMemberLookup
public struct SyntaxNode<Content> {
  let leadingTrivia: [Trivia]
  public let content: SourceRange<Content>

  func map<NewContent>(_ transform: (Content) -> NewContent) -> SyntaxNode<NewContent> {
    .init(leadingTrivia: leadingTrivia, content: content.map(transform))
  }

  public subscript<T>(dynamicMember keyPath: KeyPath<Content, T>) -> T {
    content.content[keyPath: keyPath]
  }

  public var range: SourceRange<Empty> {
    SourceRange(start: content.start, end: content.end)
  }
}

extension SyntaxNode: Equatable where Content: Equatable {}
extension SyntaxNode: Hashable where Content: Hashable {}

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

protocol SyntaxNodeContainer {
  var start: SyntaxNode<Empty> { get }
  var end: SyntaxNode<Empty> { get }
}

extension SyntaxNodeContainer {
  /// Helper for wrapping this sequence in its own syntax node.
  var syntaxNode: SyntaxNode<Self> {
    .init(
      leadingTrivia: start.leadingTrivia,
      content: .init(
        start: start.content.start,
        end: end.content.end,
        content: self
      )
    )
  }
}

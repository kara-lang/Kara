//
//  Created by Max Desiatov on 10/09/2021.
//

import Parsing

@dynamicMemberLookup
public struct SyntaxNode<Content> {
  let leadingTrivia: [Trivia]
  public let content: SourceRange<Content>

  func map<NewContent>(_ transform: (Content) throws -> NewContent) rethrows -> SyntaxNode<NewContent> {
    try .init(leadingTrivia: leadingTrivia, content: content.map(transform))
  }

  public subscript<T>(dynamicMember keyPath: KeyPath<Content, T>) -> T {
    content.content[keyPath: keyPath]
  }

  public var range: SourceRange<Empty> {
    SourceRange(start: content.start, end: content.end)
  }

  public var empty: SyntaxNode<Empty> {
    map { _ in Empty() }
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
  let inner: Inner
  let requiresLeadingTrivia: Bool

  init(_ inner: Inner, requiresLeadingTrivia: Bool = false) {
    self.inner = inner
    self.requiresLeadingTrivia = requiresLeadingTrivia
  }

  func parse(_ input: inout ParsingState) -> SyntaxNode<Content>? {
    triviaParser(requiresLeadingTrivia: requiresLeadingTrivia)
      .take(inner)
      .map { SyntaxNode(leadingTrivia: $0.map(\.content), content: $1) }
      .parse(&input)
  }
}

public protocol SyntaxNodeContainer {
  var start: SyntaxNode<Empty> { get }
  var end: SyntaxNode<Empty> { get }
}

public extension SyntaxNodeContainer {
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

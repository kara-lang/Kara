//
//  Created by Max Desiatov on 08/01/2022.
//

import Parsing

/** Generic type for syntax nodes that don't have delimiter tokens in the beginning and the end,
 and an array of elements with optional separators between them. Separators are expressed as syntax nodes
 to allow for leading trivia between any of the elements and their separators in the sequence.
 Examples of such sequences are generic constraints that don't have delimiters, but have separators.
 */
public struct UndelimitedSequence<Content> {
  public struct Element {
    let content: SyntaxNode<Content>
    let separator: SyntaxNode<Empty>?
  }

  /// An array of syntax nodes for every element of their sequence and its corresponding separator.
  let elements: [Element]

  /// Helper for retrieving an array of elements in the sequence without their syntax node information.
  public var elementsContent: [Content] {
    elements.map(\.content.content.content)
  }

  public func map<NewContent>(
    _ transform: (Content) throws -> NewContent
  ) rethrows -> UndelimitedSequence<NewContent> {
    try .init(
      elements: elements.map {
        try .init(
          content: $0.content.map(transform),
          separator: $0.separator
        )
      }
    )
  }
}

extension UndelimitedSequence: SyntaxNodeContainer {
  public var start: SyntaxNode<Empty> { elements[0].content.empty }
  public var end: SyntaxNode<Empty> { elements.last?.content.empty ?? elements[0].content.empty }
}

func undelimitedSequenceParser<T, P: Parser>(
  separatorParser: SyntaxNodeParser<Terminal, Empty>,
  elementParser: P
) -> AnyParser<ParsingState, UndelimitedSequence<T>> where P.Output == SyntaxNode<T>, P.Input == ParsingState {
  Many(
    elementParser
      .take(separatorParser)
  )
  // Optional tail component to cover cases without a trailing comma
  .take(Optional.parser(of: elementParser))
  .compactMap { head, tail -> UndelimitedSequence<T>? in
    guard let tail = tail else {
      guard head.count >= 1 else { return nil }

      return UndelimitedSequence(
        elements: head.map { .init(content: $0, separator: $1) }
      )
    }

    let result = head + [tail]

    guard result.count >= 1 else { return nil }

    return UndelimitedSequence(
      elements: head.map { .init(content: $0, separator: $1) } + [.init(content: tail, separator: nil)]
    )
  }
  .eraseToAnyParser()
}

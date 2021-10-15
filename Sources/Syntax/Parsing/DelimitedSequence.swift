//
//  Created by Max Desiatov on 14/09/2021.
//

import Parsing

/** Generic type for syntax nodes that have delimiter tokens in the beginning and the end, and an array of elements
 with optional separators between them. Delimiters and separators are expressed as syntax nodes to allow for leading
 trivia between any of the elements and their separators and delimiters in the sequence.
 Examples of such sequences are tuples (delimited by parens), arrays (square brackets), function application arguments
 (parens), generic parameters and arguments (angle brackets), etc.
 */
public struct DelimitedSequence<T>: SyntaxNodeContainer {
  struct Element {
    let content: SyntaxNode<T>
    let separator: SyntaxNode<Empty>?
  }

  /// Syntax node for the starting delimiting token of the sequence.
  let start: SyntaxNode<Empty>

  /// An array of syntax nodes for every element of their sequence and its corresponding separator.
  let elements: [Element]

  /// Syntax node for the ending delimiting token of the ssquences.
  let end: SyntaxNode<Empty>

  /// Helper for retrieving an array of elements in the sequence without their syntax node information.
  public var elementsContent: [T] {
    elements.map(\.content.content.content)
  }
}

func delimitedSequenceParser<T, P: Parser>(
  startParser: SyntaxNodeParser<Terminal, Empty>,
  endParser: SyntaxNodeParser<Terminal, Empty>,
  elementParser: P,
  atLeast minimum: Int = 0
) -> AnyParser<ParsingState, DelimitedSequence<T>> where P.Output == SyntaxNode<T>, P.Input == ParsingState {
  startParser
    .take(
      Many(
        elementParser
          .take(SyntaxNodeParser(commaParser))
      )
    )
    // Optional tail component to cover cases without a trailing comma
    .take(Optional.parser(of: elementParser))
    .take(endParser)
    .compactMap { startNode, head, tail, endNode -> DelimitedSequence<T>? in
      guard let tail = tail else {
        guard head.count >= minimum else { return nil }

        return DelimitedSequence(
          start: startNode,
          elements: head.map { .init(content: $0, separator: $1) },
          end: endNode
        )
      }

      let result = head + [tail]

      guard result.count >= minimum else { return nil }

      return DelimitedSequence(
        start: startNode,
        elements: head.map { .init(content: $0, separator: $1) } + [.init(content: tail, separator: nil)],
        end: endNode
      )
    }
    .eraseToAnyParser()
}

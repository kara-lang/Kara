//
//  Created by Max Desiatov on 14/09/2021.
//

import Parsing

public struct DelimitedSequence<T> {
  let start: SyntaxNode<()>
  let elements: [(SyntaxNode<T>, SyntaxNode<()>?)]
  let end: SyntaxNode<()>

  public var elementsContent: [T] {
    elements.map(\.0.content.content)
  }

  var syntaxNode: SyntaxNode<DelimitedSequence<T>> {
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

func delimitedSequenceParser<T, P: Parser>(
  startParser: Terminal,
  endParser: Terminal,
  elementParser: P,
  atLeast minimum: Int = 0
) -> AnyParser<ParsingState, DelimitedSequence<T>> where P.Output == SyntaxNode<T>, P.Input == ParsingState {
  SyntaxNodeParser(startParser)
    .take(
      Many(
        elementParser
          .take(SyntaxNodeParser(commaParser))
      )
    )
    .take(Optional.parser(of: elementParser))
    .take(SyntaxNodeParser(endParser))
    .compactMap { startNode, head, tail, endNode -> DelimitedSequence<T>? in
      guard let tail = tail else {
        guard head.count >= minimum else { return nil }

        return DelimitedSequence(start: startNode, elements: head, end: endNode)
      }

      let result = head + [tail]

      guard result.count >= minimum else { return nil }

      return DelimitedSequence(start: startNode, elements: head + [(tail, nil)], end: endNode)
    }
    .eraseToAnyParser()
}

//
//  Created by Max Desiatov on 14/09/2021.
//

import Parsing

struct DelimitedSequence<T> {
  let start: SyntaxNode<UTF8SubSequence>
  let elements: [(SyntaxNode<T>, SyntaxNode<UTF8SubSequence>?)]
  let end: SyntaxNode<UTF8SubSequence>
}

func delimitedSequenceParser<T, P: Parser>(
  startParser: Terminal,
  endParser: Terminal,
  elementParser: P,
  atLeast minimum: Int = 0
) -> AnyParser<ParsingState, SyntaxNode<[SyntaxNode<T>]>> where P.Output == SyntaxNode<T>, P.Input == ParsingState {
  startParser
    .take(
      Many(
        SyntaxNodeParser(elementParser)
          .take(SyntaxNodeParser(commaParser))
      )
    )
    .take(Optional.parser(of: SyntaxNodeParser(elementParser)))
    .take(SyntaxNodeParser(endParser))
    .compactMap { startToken, head, tail, endToken -> SyntaxNode<[SyntaxNode<T>]>? in
      guard let tail = tail else {
        guard head.count >= minimum else { return nil }

        return SyntaxNode(
          start: startToken.start,
          end: endToken.end,
          content: head
        )
      }

      let result = head + [tail]

      guard result.count >= minimum else { return nil }

      return SourceRange(start: startToken.start, end: endToken.end, content: head + [tail])
    }
    .eraseToAnyParser()
}

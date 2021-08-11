//
//  Created by Max Desiatov on 10/08/2021.
//

import Parsing

struct ParsingState {
  let source: String
  var currentIndex: String.Index
  var currentCharacter = 0
  var currentLine = 0
}

struct StatefulParser<P: Parser>: Parser where P.Input == Substring {
    let inner: P

    func parse(_ state: inout ParsingState) -> SourceLocation<P.Output>? {
        let start = state.currentIndex

        var substring = state.source[state.currentIndex...]
        guard let output = inner.parse(&substring) else {
            return nil
        }

        state.currentIndex = substring.startIndex

        return SourceLocation(start: start, end: state.source.index(before: state.currentIndex), element: output)
    }
}

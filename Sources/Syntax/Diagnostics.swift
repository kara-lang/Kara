//
//  Created by Max Desiatov on 10/08/2021.
//

import Parsing

struct SourceLocation<Element> {
  let start: String.Index
  let end: String.Index

  let element: Element
}

struct LineCount<Output> {
  /** Every element of this array encodes a number of characters found in a parsed string.
    For example, string `"abcdef"` is encoded as `[6]`, `"abcdef\n"` as `[6, 0]`, `"abc\ndef"` as `[3, 3]`.
   */
  let lines: [Int]

  let output: Output
}

struct CharacterCounter<P: Parser>: Parser where P.Input: Collection {
  let inner: P

  func parse(_ input: inout P.Input) -> LineCount<P.Output>? {
    let initialCount = input.count

    guard let output = inner.parse(&input) else {
      return nil
    }

    return LineCount(lines: [initialCount - input.count], output: output)
  }
}

//
//  Created by Max Desiatov on 19/08/2021.
//

import Parsing

struct Lookahead<Inner: Parser>: Parser where Inner.Input: Collection {
  let inner: Inner
  let amount: Int
  let isValid: (Input.SubSequence) -> Bool

  func parse(_ input: inout Inner.Input) -> Inner.Output? {
    let oldInput = input
    let output = inner.parse(&input)

    guard let output = output, isValid(input.prefix(amount)) else {
      input = oldInput
      return nil
    }

    return output
  }
}

extension Parser where Input: Collection {
  func lookahead(
    amount: Int,
    _ isValid: @escaping (Input.SubSequence) -> Bool
  ) -> Lookahead<Self> {
    Lookahead(inner: self, amount: amount, isValid: isValid)
  }
}

//
//  Created by Max Desiatov on 19/08/2021.
//

import Parsing

struct Lookahead<Upstream: Parser>: Parser where Upstream.Input: Collection {
  let upstream: Upstream
  let amount: Int
  let validator: (Input.SubSequence) -> Bool

  func parse(_ input: inout Upstream.Input) -> Upstream.Output? {
    let oldInput = input
    let output = upstream.parse(&input)

    guard let output = output, validator(input.prefix(amount)) else {
      input = oldInput
      return nil
    }

    return output
  }
}

extension Parser where Input: Collection {
  func lookahead(
    amount: Int,
    _ validator: @escaping (Input.SubSequence) -> Bool
  ) -> Lookahead<Self> {
    Lookahead(upstream: self, amount: amount, validator: validator)
  }
}

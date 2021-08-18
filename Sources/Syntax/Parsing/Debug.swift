//
//  Created by Max Desiatov on 19/08/2021.
//

import Parsing

struct Debug<Upstream: Parser>: Parser {
  let upstream: Upstream

  func parse(_ input: inout Upstream.Input) -> Upstream.Output? {
    print("Input before parsing: \(input)")

    let output = upstream.parse(&input)

    print("Input after parsing: \(input)")
    print("Parsing output: \(String(describing: output))")

    return output
  }
}

extension Parser {
  func debug() -> Debug<Self> {
    Debug(upstream: self)
  }
}

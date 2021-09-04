//
//  Created by Max Desiatov on 19/08/2021.
//

import Parsing

struct Debug<Upstream: Parser>: Parser {
  let upstream: Upstream
  let file: StaticString
  let line: Int

  func parse(_ input: inout Upstream.Input) -> Upstream.Output? {
    let oldInput = input

    let output = upstream.parse(&input)

    print("Debug formed at \(file):\(line)")
    if output != nil {
      print("Input before parsing: \(String(describing: oldInput))")
      print("Input after parsing: \(String(describing: input))")
    }
    print("Parsing output: \(String(describing: output))")

    return output
  }
}

extension Parser {
  func debug(file: StaticString = #file, line: Int = #line) -> Debug<Self> {
    Debug(upstream: self, file: file, line: line)
  }
}

extension UTF8SubSequence: CustomDebugStringConvertible {
  public var debugDescription: String {
    String(Substring(self))
  }
}

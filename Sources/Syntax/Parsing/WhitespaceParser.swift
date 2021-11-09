//
//  Created by Max Desiatov on 09/11/2021.
//

import Parsing

/// A parser that consumes all ` ` symbols from the beginning of the input.
public struct WhitespaceParser<Input>: Parser
  where
  Input: Collection,
  Input.SubSequence == Input,
  Input.Element == UTF8.CodeUnit
{
  @inlinable
  public init() {}

  @inlinable
  public func parse(_ input: inout Input) -> Input? {
    let output = input.prefix(while: { (byte: UTF8.CodeUnit) in
      byte == .init(ascii: " ")
    })
    input.removeFirst(output.count)
    return output
  }
}

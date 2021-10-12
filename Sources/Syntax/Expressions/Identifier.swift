//
//  Created by Max Desiatov on 12/08/2021.
//

import Parsing

public struct Identifier: Hashable {
  public let value: String
}

extension Identifier: ExpressibleByStringLiteral {
  public init(stringLiteral value: StringLiteralType) {
    self.init(value: value)
  }
}

extension Identifier: CustomStringConvertible {
  public var description: String { value }
}

/// Identifiers can only start with a lowercase letter or an underscore.
let identifierHead = [
  UInt8(ascii: "_"),
] + Array(UInt8(ascii: "a")...UInt8(ascii: "z"))

let identifierTail = identifierHead + Array(UInt8(ascii: "A")...UInt8(ascii: "Z")) +
  Array(UInt8(ascii: "0")...UInt8(ascii: "9"))

let identifierSequenceParser =
  First<UTF8SubSequence>().filter { identifierHead.contains($0) }
    .take(Prefix { identifierTail.contains($0) })
    .compactMap { String(bytes: [$0] + Array($1), encoding: .utf8) }

let identifierParser = SyntaxNodeParser(
  identifierSequenceParser
    .map { Identifier(value: $0) }
    .stateful()
)

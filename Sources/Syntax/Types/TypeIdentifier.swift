//
//  Created by Max Desiatov on 21/08/2021.
//

import Parsing

public struct TypeIdentifier: Hashable {
  public let value: String
}

extension TypeIdentifier: ExpressibleByStringLiteral {
  public init(stringLiteral value: String) {
    self.value = value
  }
}

extension TypeIdentifier: CustomDebugStringConvertible {
  public var debugDescription: String {
    value
  }
}

/// TypeIdentifiers can only start with an uppercase letter.
let typeIdentifierHead = UInt8(ascii: "A")...UInt8(ascii: "Z")

let typeIdentifierSequenceParser =
  First<UTF8SubSequence>().filter { typeIdentifierHead.contains($0) }
    .take(Prefix { identifierTail.contains($0) })
    .compactMap { String(bytes: [$0] + Array($1), encoding: .utf8) }

let typeIdentifierParser = SyntaxNodeParser(
  typeIdentifierSequenceParser
    .map { TypeIdentifier(value: $0) }
    .stateful()
)

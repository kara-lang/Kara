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

/// Identifiers can only start with a letter or an underscore, digits are not allowed.
let identifierHead = [
  UInt8(ascii: "_"),
] + Array(UInt8(ascii: "A")...UInt8(ascii: "Z")) + Array(UInt8(ascii: "a")...UInt8(ascii: "z"))

let identifierTail = identifierHead +
  Array(UInt8(ascii: "0")...UInt8(ascii: "9"))

let identifierSequenceParser =
  First<UTF8SubSequence>().filter { identifierHead.contains($0) }
    .take(Prefix {
      identifierTail.contains($0)
    })
    .compactMap { String(bytes: [$0] + Array($1), encoding: .utf8) }

typealias IdentifierParser = SyntaxNodeParser<
  StatefulParser<Parsers.CompactMap<
    Parsers.CompactMap<Parsers.Take2<Parsers.Filter<First<UTF8SubSequence>>, Prefix<UTF8SubSequence>>, String>,
    Identifier
  >>,
  Identifier
>

func identifierParser(requiresLeadingTrivia: Bool = false) -> IdentifierParser {
  SyntaxNodeParser(
    identifierSequenceParser
      .compactMap { rawIdentifier -> Identifier? in
        guard !Keyword.allCases.map(\.rawValue).contains(rawIdentifier) else { return nil }

        return Identifier(value: rawIdentifier)
      }
      .stateful(),
    requiresLeadingTrivia: requiresLeadingTrivia
  )
}

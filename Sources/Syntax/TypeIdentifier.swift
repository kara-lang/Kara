//
//  Created by Max Desiatov on 21/08/2021.
//

import Parsing

public struct TypeIdentifier: Hashable {
  let value: String
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

let typeIdentifierParser = identifierSequenceParser
  .map { TypeIdentifier(value: $0) }
  .stateful()

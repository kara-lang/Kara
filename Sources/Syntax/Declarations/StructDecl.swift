//
//  Created by Max Desiatov on 11/08/2021.
//

import Parsing

public struct StructDecl {
  let name: SourceRange<TypeIdentifier>
  let genericParameters: [TypeVariable]
}

extension StructDecl: CustomDebugStringConvertible {
  public var debugDescription: String {
    if genericParameters.isEmpty {
      return "struct \(name) {}"
    } else {
      return "struct \(name)<\(genericParameters.map(\.debugDescription).joined(separator: ", "))> {}"
    }
  }
}

let structParser = Terminal("struct")
  .skip(statefulWhitespace(isRequired: true))
  .take(typeIdentifierParser)
  .skipWithWhitespace(openBraceParser)
  .skipWithWhitespace(closeBraceParser)
  .map(\.1)
  // FIXME: generic parameters
  .map { StructDecl(name: $0, genericParameters: []) }

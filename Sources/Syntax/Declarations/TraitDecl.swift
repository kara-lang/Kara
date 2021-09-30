//
//  Created by Max Desiatov on 03/09/2021.
//

import Parsing

public struct TraitDecl {
  let name: SourceRange<TypeIdentifier>
}

extension TraitDecl: CustomStringConvertible {
  public var description: String {
    "trait \(name) {}"
  }
}

let traitParser = Terminal("trait")
  .skip(statefulWhitespace(isRequired: true))
  .take(typeIdentifierParser)
  .skipWithWhitespace(openBraceParser)
  .skipWithWhitespace(closeBraceParser)
  .map(\.1)
  // FIXME: generic parameters
  .map { TraitDecl(name: $0) }

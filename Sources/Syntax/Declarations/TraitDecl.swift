//
//  Created by Max Desiatov on 03/09/2021.
//

import Parsing

struct TraitDecl {
  let name: SourceRange<TypeIdentifier>
}

extension TraitDecl: CustomDebugStringConvertible {
  public var debugDescription: String {
    "trait \(name) {}"
  }
}

let traitParser = Terminal("trait")
  .skip(StatefulWhitespace(isRequired: true))
  .take(typeIdentifierParser)
  .skip(StatefulWhitespace())
  .skip(openBraceParser)
  .skip(StatefulWhitespace())
  .skip(closeBraceParser)
  .map(\.1)
  // FIXME: generic parameters
  .map { TraitDecl(name: $0) }

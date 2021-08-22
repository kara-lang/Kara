//
//  Created by Max Desiatov on 11/08/2021.
//

import Parsing

struct StructDecl: Equatable {
  let name: SourceRange<TypeIdentifier>
  let genericParameters: [TypeVariable]
}

let structParser = Terminal("struct")
  .skip(StatefulWhitespace(isRequired: true))
  .take(typeIdentifierParser)
  .skip(StatefulWhitespace())
  .skip(openBraceParser)
  .skip(StatefulWhitespace())
  .skip(closeBraceParser)
  .map(\.1)
  // FIXME: generic parameters
  .map { StructDecl(name: $0, genericParameters: []) }

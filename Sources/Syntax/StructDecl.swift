//
//  Created by Max Desiatov on 11/08/2021.
//

import Parsing

struct StructDecl: Equatable {
  let name: TypeIdentifier
  let genericParameters: [TypeVariable]
}

let structParser = UTF8Terminal("struct".utf8)
  .skip(requiredWhitespaceParser)
  .take(Prefix { $0 != .init(ascii: "{") && !newlineAndWhitespace.contains($0) })
  .skip(whitespaceParser)
  .skip(openBraceParser)
  .skip(whitespaceParser)
  .skip(closeBraceParser)
  // FIXME: generic parameters
  .compactMap(String.init)
  .map { StructDecl(name: .init(value: $0), genericParameters: []) }

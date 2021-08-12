//
//  Created by Max Desiatov on 11/08/2021.
//

import Parsing

struct BindingDecl {
  let identifier: Identifier
  let value: Expr
}

let bindingParser = UTF8Terminal("let".utf8)
  .skip(whitespaceParser)
  .take(Prefix { newlineAndWhitespace.contains($0) })
  .skip(whitespaceParser)
  .skip(StartsWith("=".utf8))
  .skip(whitespaceParser)
  .take(exprParser)
  .compactMap { identifierUTF8, expr -> BindingDecl? in
    guard let identifierString = String(identifierUTF8) else { return nil }

    return BindingDecl(
      identifier: Identifier(value: identifierString),
      value: expr
    )
  }

//
//  Created by Max Desiatov on 11/08/2021.
//

import Parsing

struct BindingDecl {
  let identifier: Identifier
  let value: Expr
}

let bindingParser = Terminal("let")
  .takeSkippingWhitespace(identifierParser)
  .skipWithWhitespace(Terminal("="))
  .takeSkippingWhitespace(exprParser)
  .map { letTerminal, identifier, expr in
    SourceRange(
      start: letTerminal.start,
      end: expr.end,
      content: BindingDecl(identifier: identifier.content, value: expr.content)
    )
  }

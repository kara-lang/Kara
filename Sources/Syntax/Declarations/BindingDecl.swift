//
//  Created by Max Desiatov on 11/08/2021.
//

import Parsing

struct BindingDecl {
  let identifier: Identifier
  let value: Expr
}

let bindingParser = Terminal("let")
  .skip(StatefulWhitespace())
  .take(identifierParser)
  .skip(StatefulWhitespace())
  .skip(Terminal("="))
  .skip(StatefulWhitespace())
  .take(exprParser)
  .map { letTerminal, identifier, expr in
    SourceRange(
      start: letTerminal.start,
      end: expr.end,
      element:
      BindingDecl(identifier: identifier.element, value: expr.element)
    )
  }

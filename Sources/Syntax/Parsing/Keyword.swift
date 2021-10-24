//
//  Created by Max Desiatov on 22/10/2021.
//

import Parsing

enum Keyword: String, CaseIterable {
  case `struct`
  case `enum`
  case trait
  case `func`
  case `if`
  case `else`
  case `in`
  case `let`
  case `public`
  case `private`
  case `static`
  case interop
  case `true`
  case `false`

  var parser: SyntaxNodeParser<Terminal, Empty> {
    .init(Terminal(rawValue))
  }
}

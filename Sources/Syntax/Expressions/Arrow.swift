//
//  Created by Max Desiatov on 20/10/2021.
//

import Parsing

struct Arrow {
  let head: SyntaxNode<Expr>
  let arrowSymbol: SyntaxNode<Empty>
  let tail: SyntaxNode<Expr>
}

let arrowTailParser = Parse {
  arrowSymbolParser
  Lazy { exprParser }
}

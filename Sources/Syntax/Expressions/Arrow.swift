//
//  Created by Max Desiatov on 20/10/2021.
//

import Parsing

/// `A -> B` type expressions.
struct Arrow<A: Annotation> {
  let head: SyntaxNode<Expr<A>>
  let arrowSymbol: SyntaxNode<Empty>
  let tail: SyntaxNode<Expr<A>>
}

let arrowTailParser = SyntaxNodeParser(Terminal("->"))
  .take(Lazy { exprParser() })

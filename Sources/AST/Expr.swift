//
//  Created by Max Desiatov on 11/08/2021.
//

public indirect enum Expr {
  case identifier(Identifier)
  case application(Expr, [Expr])
  case lambda([Identifier], Expr)
  case literal(Literal)
  case ternary(Expr, Expr, Expr)
  case member(Expr, Identifier)
  case namedTuple([(Identifier?, Expr)])

  static func tuple(_ expressions: [Expr]) -> Expr {
    .namedTuple(expressions.enumerated().map {
      (nil, $0.1)
    })
  }
}

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

  public static func tuple(_ expressions: [Expr]) -> Expr {
    .namedTuple(expressions.enumerated().map {
      (nil, $0.1)
    })
  }
}

extension Expr: ExpressibleByStringLiteral {
  public init(stringLiteral value: String) {
    self = .identifier(.init(value: value))
  }
}

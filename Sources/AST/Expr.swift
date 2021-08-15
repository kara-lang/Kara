//
//  Created by Max Desiatov on 11/08/2021.
//

import Parsing

public indirect enum Expr {
  case identifier(Identifier)
  case application(Expr, [Expr])
  case lambda([Identifier], Expr)
  case literal(Literal)
  case ternary(Expr, Expr, Expr)
  case member(Expr, Identifier)
  case namedTuple(Tuple)

  public static func tuple(_ expressions: [Expr]) -> Expr {
    .namedTuple(.init(elements: expressions.map {
      .init(name: nil, expr: $0)
    }))
  }
}

extension Expr: ExpressibleByStringLiteral {
  public init(stringLiteral value: String) {
    self = .identifier(.init(value: value))
  }
}

extension Expr: Equatable {
  public static func == (lhs: Self, rhs: Self) -> Bool {
    switch (lhs, rhs) {
    case let (.identifier(i1), .identifier(i2)):
      return i1 == i2
    case let (.application(e1, args1), .application(e2, args2)):
      return e1 == e2 && args1 == args2
    case let (.lambda(params1, body1), .lambda(params2, body2)):
      return params1 == params2 && body1 == body2
    case let (.literal(l1), .literal(l2)):
      return l1 == l2
    case let (.ternary(i1, t1, e1), .ternary(i2, t2, e2)):
      return i1 == i2 && t1 == t2 && e1 == e2
    case let (.member(e1, i1), .member(e2, i2)):
      return e1 == e2 && i1 == i2
    case let (.namedTuple(t1), .namedTuple(t2)):
      return t1 == t2
    default:
      return false
    }
  }
}

let applicationParser = exprParserFactory()
  .skip(Whitespace())
  .skip(openParenParser)
  .skip(Whitespace())
  .take(
    Many(
      exprParserFactory()
        .skip(Whitespace())
        .skip(commaParser)
        .skip(Whitespace())
    )
  )
  .skip(Whitespace())
  .skip(closeParenParser)
  .map { Expr.application($0, $1) }

func exprParserFactory() -> AnyParser<UTF8Subsequence, Expr> {
  literalParser.map(Expr.literal)
    .orElse(identifierParser.map(Expr.identifier))
    .eraseToAnyParser()
}

let exprParser = exprParserFactory()

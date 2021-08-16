//
//  Created by Max Desiatov on 11/08/2021.
//

import Parsing

public indirect enum Expr {
  case identifier(Identifier)
  case application(Expr, [Expr])
  case lambda(Lambda)
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

extension Expr: CustomDebugStringConvertible {
  public var debugDescription: String {
    switch self {
    case let .identifier(i):
      return i.value
    case let .application(function, args):
      return "\(function)(\(args.map(\.debugDescription).joined(separator: ", "))"
    case let .lambda(l):
      return "{ \(l.parameters.map(\.identifier.value).joined(separator: ", ")) in \(l.body.debugDescription)}"
    case let .literal(l):
      return l.debugDescription
    case let .ternary(i, t, e):
      return
        """
        if \(i.debugDescription) {
          \(t.debugDescription)
        } else {
          \(e.debugDescription)
        }
        """
    case let .member(expr, member):
      return "\(expr.debugDescription).\(member.value)"
    case let .namedTuple(tuple):
      return "(\(tuple.elements.map(\.expr.debugDescription).joined(separator: ", "))"
    }
  }
}

extension Expr: Equatable {
  public static func == (lhs: Self, rhs: Self) -> Bool {
    switch (lhs, rhs) {
    case let (.identifier(i1), .identifier(i2)):
      return i1 == i2
    case let (.application(e1, args1), .application(e2, args2)):
      return e1 == e2 && args1 == args2
    case let (.lambda(l1), .lambda(l2)):
      return l1 == l2
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

let applicationParser = exprParser
  .skip(Whitespace())
  .take(tupleSequenceParser)
  .map { Expr.application($0, $1) }

let exprParser =
  literalParser.map(Expr.literal)
    .orElse(identifierParser.map(Expr.identifier))
    .orElse(tupleParser)

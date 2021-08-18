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
  case tuple(Tuple)

  static var unit: Expr { .tuple(.init()) }
}

extension Expr: ExpressibleByStringLiteral {
  public init(stringLiteral value: String) {
    self = .identifier(.init(value: value))
  }
}

extension Expr: ExpressibleByIntegerLiteral {
  public init(integerLiteral value: Int) {
    self = .literal(.integer(value))
  }
}

extension Expr: CustomDebugStringConvertible {
  public var debugDescription: String {
    switch self {
    case let .identifier(i):
      return i.value
    case let .application(function, args):
      return "\(function)(\(args.map(\.debugDescription).joined(separator: ", ")))"
    case let .lambda(l):
      return l.debugDescription
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
    case let .tuple(tuple):
      return "(\(tuple.elements.map(\.expr.element.debugDescription).joined(separator: ", ")))"
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
    case let (.tuple(t1), .tuple(t2)):
      return t1 == t2
    default:
      return false
    }
  }
}

// private enum ExprTail {
//  case memberAccess(Identifier)
//  case applicationArguments([Expr])
// }
//
// private let memberAccessParser =
//  Whitespace()
//    .ignoreOutput()
//    .skip(
//      UTF8Terminal(".".utf8)
//    )
//    .take(identifierParser)
//    .map(ExprTail.memberAccess)
//
// private let applicationArgumentsParser =
//  Whitespace()
//    .ignoreOutput()
//    .take(tupleSequenceParser)
//    .map(ExprTail.applicationArguments)

public let exprParser: AnyParser<ParsingState, SourceLocation<Expr>> =
  literalParser.map(Expr.literal).stateful()
    .orElse(identifierParser.map(Expr.identifier).stateful())
//    .orElse(tupleParser.map(Expr.tuple))
//    .orElse(lambdaParser.map(Expr.lambda))
//
//    // Structuring the parser this way with `map` and `Many` to avoid left recursion for certain
//    // derivations. Expressing left recursion with combinators directly without breaking up derivations
//    // leads to infinite loops.
//    .take(Many(memberAccessParser.orElse(applicationArgumentsParser)))
//    .map { expr, tail -> Expr in
//      tail.reduce(expr) { reducedExpr, tailElement in
//        switch tailElement {
//        case let .memberAccess(identifier):
//          return Expr.member(reducedExpr, identifier)
//        case let .applicationArguments(arguments):
//          return Expr.application(reducedExpr, arguments)
//        }
//      }
//    }
    // Required to give `exprParser` an explicit type signature, otherwise this won't compile due to mutual
    // recursion with subexpression parsers.
    .eraseToAnyParser()

//
//  Created by Max Desiatov on 11/08/2021.
//

import Parsing

public indirect enum Expr {
  case identifier(Identifier)
  case application(FunctionApplication)
  case lambda(Lambda)
  case literal(Literal)
  case ternary(Expr, Expr, Expr)
  case member(Expr, Identifier)
  case tuple(Tuple)

  public static var unit: Expr { .tuple(.init(elements: [])) }
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
    case let .application(app):
      return "\(app.function.element)(\(app.arguments.map(\.element.debugDescription).joined(separator: ", ")))"
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
    case let (.application(a1), .application(a2)):
      return a1 == a2
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

private enum ExprTail {
  case memberAccess(SourceRange<Identifier>)
  case applicationArguments(SourceRange<[SourceRange<Expr>]>)
}

private let memberAccessParser =
  StatefulWhitespace()
    .ignoreOutput()
    .skip(
      Terminal(".")
    )
    .take(identifierParser)
    .map(ExprTail.memberAccess)

private let applicationArgumentsParser =
  StatefulWhitespace()
    .ignoreOutput()
    .take(tupleSequenceParser)
    .map(ExprTail.applicationArguments)

public let exprParser: AnyParser<ParsingState, SourceRange<Expr>> =
  literalParser.map(Expr.literal).stateful()
    .orElse(identifierParser.map { $0.map(Expr.identifier) })
    .orElse(tupleParser.map { $0.map(Expr.tuple) })
    .orElse(lambdaParser.map { $0.map(Expr.lambda) })

    // Structuring the parser this way with `map` and `Many` to avoid left recursion for certain
    // derivations. Expressing left recursion with combinators directly without breaking up derivations
    // leads to infinite loops.
    .take(Many(memberAccessParser.orElse(applicationArgumentsParser)))
    .map { expr, tail -> SourceRange<Expr> in
      tail.reduce(expr) { reducedExpr, tailElement in
        switch tailElement {
        case let .memberAccess(identifier):
          return .init(
            start: reducedExpr.start,
            end: identifier.end,
            element: .member(reducedExpr.element, identifier.element)
          )
        case let .applicationArguments(arguments):
          return .init(
            start: reducedExpr.start,
            end: arguments.end,
            element: .application(.init(function: reducedExpr, arguments: arguments.element))
          )
        }
      }
    }
    // Required to give `exprParser` an explicit type signature, otherwise this won't compile due to mutual
    // recursion with subexpression parsers.
    .eraseToAnyParser()

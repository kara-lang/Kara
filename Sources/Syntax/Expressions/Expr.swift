//
//  Created by Max Desiatov on 11/08/2021.
//

import Parsing

public indirect enum Expr {
  case identifier(Identifier)
  case application(FunctionApplication)
  case closure(Closure)
  case literal(Literal)
  case ifThenElse(IfThenElse)
  case member(MemberAccess)
  case tuple(Tuple<Expr>)

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
      return "\(app.function.content)(\(app.arguments.map(\.content.debugDescription).joined(separator: ", ")))"
    case let .closure(l):
      return l.debugDescription
    case let .literal(l):
      return l.debugDescription
    case let .ifThenElse(ifThenElse):
      return
        """
        if \(ifThenElse.condition.content.debugDescription) {
          \(ifThenElse.thenBranch.content.debugDescription)
        } else {
          \(ifThenElse.elseBranch.content.debugDescription)
        }
        """
    case let .member(memberAccess):
      return "\(memberAccess.base.content.debugDescription).\(memberAccess.member.content.value)"
    case let .tuple(tuple):
      return "(\(tuple.elements.map(\.content.debugDescription).joined(separator: ", ")))"
    }
  }
}

enum ExprSyntaxTail {
  case memberAccess(SourceRange<Identifier>)
  case applicationArguments(SourceRange<[SourceRange<Expr>]>)
}

// FIXME: make it internal
public let exprParser: AnyParser<ParsingState, SyntaxNode<Expr>> =
  literalParser.map(Expr.literal).stateful()
    .orElse(ifThenElseParser.map { $0.map(Expr.ifThenElse) })
    .orElse(identifierParser.map { $0.map(Expr.identifier) })
    .orElse(tupleExprParser.map { $0.map(Expr.tuple) })
    .orElse(closureParser.map { $0.map(Expr.closure) })

    // Structuring the parser this way with `map` and `Many` to avoid left recursion for certain
    // derivations, specifically member access and function application. Expressing left recursion with combinators
    // directly, without breaking up derivations into head and tail components, leads to infinite loops.
    .take(Many(memberAccessParser.orElse(applicationArgumentsParser)))
    .map { expr, tail -> SyntaxNode<Expr> in
      tail.reduce(expr) { reducedExpr, tailElement in
        switch tailElement {
        case let .memberAccess(identifier):
          return SyntaxNode(
            leadingTrivia: [],
            content: .init(
              start: reducedExpr.start,
              end: identifier.end,
              content: .member(.init(base: reducedExpr, member: identifier))
            )
          )
        case let .applicationArguments(arguments):
          return SyntaxNode(
            leadingTrivia: [],
            content: .init(
              start: reducedExpr.start,
              end: arguments.end,
              content: .application(.init(function: reducedExpr, arguments: arguments.content))
            )
          )
        }
      }
    }
    // Required to give `exprParser` an explicit type signature, otherwise this won't compile due to mutual
    // recursion with subexpression parsers.
    .eraseToAnyParser()

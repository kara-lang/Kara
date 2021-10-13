//
//  Created by Max Desiatov on 11/08/2021.
//

import Parsing

public indirect enum Expr {
  case identifier(Identifier)
  case application(FuncApplication)
  case closure(Closure)
  case literal(Literal)
  case ifThenElse(IfThenElse)
  case member(MemberAccess)
  case tuple(DelimitedSequence<Expr>)
  case block(ExprBlock)
  case structLiteral(StructLiteral)
  case type(Type)
  case unit
}

extension Expr: ExpressibleByStringLiteral {
  public init(stringLiteral value: String) {
    self = .identifier(.init(value: value))
  }
}

extension Expr: ExpressibleByIntegerLiteral {
  public init(integerLiteral value: Int) {
    self = .literal(Literal(integerLiteral: value))
  }
}

enum ExprSyntaxTail {
  case memberAccess(dot: SyntaxNode<()>, SyntaxNode<Identifier>)
  case applicationArguments(DelimitedSequence<Expr>)
}

let exprParser: AnyParser<ParsingState, SyntaxNode<Expr>> =
  SyntaxNodeParser(literalParser.map(Expr.literal).stateful())
    .orElse(ifThenElseParser.map { $0.map(Expr.ifThenElse) })
    .orElse(identifierParser.map { $0.map(Expr.identifier) })
    .orElse(tupleExprParser.map { $0.syntaxNode.map(Expr.tuple) })
    .orElse(closureParser.map { $0.map(Expr.closure) })
    .orElse(typeParser.map { $0.map(Expr.type) })

    // Structuring the parser this way with `map` and `Many` to avoid left recursion for certain
    // derivations, specifically member access and function application. Expressing left recursion with combinators
    // directly, without breaking up derivations into head and tail components, leads to infinite loops.
    .take(Many(memberAccessParser.orElse(applicationArgumentsParser)))
    .map { (expr: SyntaxNode<Expr>, tail: [ExprSyntaxTail]) -> SyntaxNode<Expr> in
      tail.reduce(expr) { reducedExpr, tailElement in
        switch tailElement {
        case let .memberAccess(dot, identifier):
          return SyntaxNode(
            leadingTrivia: expr.leadingTrivia,
            content: .init(
              start: reducedExpr.content.start,
              end: identifier.content.end,
              content: .member(.init(base: reducedExpr, dot: dot, member: identifier))
            )
          )
        case let .applicationArguments(arguments):
          return SyntaxNode(
            leadingTrivia: expr.leadingTrivia,
            content: .init(
              start: reducedExpr.content.start,
              end: arguments.end.content.end,
              content: .application(.init(function: reducedExpr, arguments: arguments))
            )
          )
        }
      }
    }
    // Required to give `exprParser` an explicit type signature, otherwise this won't compile due to mutual
    // recursion with subexpression parsers.
    .eraseToAnyParser()

//
//  Created by Max Desiatov on 11/08/2021.
//

import Parsing

/// Protocol grouping possible expression annotations.
public protocol Annotation {}

public struct EmptyAnnotation: Annotation {}

/// Syntax node representing an expression. It can also have an optional annotation attached to it, otherwise
/// `EmptyAnnotation` type is used as a generic argument passed to `Expr` type constructor.
public struct Expr<A: Annotation> {
  public init(payload: Payload, annotation: A) {
    self.payload = payload
    self.annotation = annotation
  }

  public indirect enum Payload {
    case identifier(Identifier)
    case application(FuncApplication<A>)
    case closure(Closure<A>)
    case literal(Literal)
    case ifThenElse(IfThenElse<A>)
    case `switch`(Switch<A>)
    case member(MemberAccess<A>)
    case tuple(DelimitedSequence<Expr<A>>)
    case block(ExprBlock<A>)
    case structLiteral(StructLiteral<A>)
    case leadingDot(LeadingDot)
    case unit
  }

  public let payload: Payload
  public let annotation: A
}

public extension Expr where A == EmptyAnnotation {
  /// Trivial helper initializer for initializing expressions with empty annotations.
  /// - Parameter payload: the actual expression to be stored without any annotation.
  init(_ payload: Expr<EmptyAnnotation>.Payload) {
    self.payload = payload
    annotation = .init()
  }
}

extension Expr: ExpressibleByIntegerLiteral where A == EmptyAnnotation {
  public init(integerLiteral value: Int) {
    self.init(.literal(Literal(integerLiteral: value)))
  }
}

/// Helper type used to avoid left recursion when parsing. Complex expressions such as member access `a.b`,
/// function application `f(x)`, and struct literals `S {a: b}` contain subexpressions as their first part. If we
/// naively parse subexpressions recursively, this will lead to an infinite loop. Therefore, we need to split the
/// parsing process into two stages:
/// 1. Parse expressions that don't have subexpressions as their first part.
/// 2. Optionally parse possible tails of complex expressions that may have subexpressions as their first part.
/// The result of step 2 (if present) is stored in `ExprSyntaxTail` and then concatenated with the result from step 1.
enum ExprSyntaxTail {
  case memberAccess(dot: SyntaxNode<Empty>, SyntaxNode<Member>)
  case applicationArguments(DelimitedSequence<Expr<EmptyAnnotation>>)
  case structLiteral(DelimitedSequence<StructLiteral<EmptyAnnotation>.Element>)
}

func exprParser(includeStructLiteral: Bool = true) -> AnyParser<ParsingState, SyntaxNode<Expr<EmptyAnnotation>>> {
  SyntaxNodeParser(literalParser.map(Expr.Payload.literal).stateful())
    .orElse(ifThenElseParser.map { $0.map(Expr.Payload.ifThenElse) })
    .orElse(identifierParser().map { $0.map(Expr.Payload.identifier) })
    .orElse(tupleExprParser.map { $0.syntaxNode.map(Expr.Payload.tuple) })
    .orElse(closureParser.map { $0.map(Expr.Payload.closure) })
    .orElse(leadingDotParser.map { $0.map(Expr.Payload.leadingDot) })
    .orElse(switchParser.map { $0.map(Expr.Payload.switch) })
    .map { $0.map(Expr<EmptyAnnotation>.init) }

    // Structuring the parser this way with `map` and `Many` to avoid left recursion for certain
    // derivations, specifically member access and function application. Expressing left recursion with combinators
    // directly, without breaking up derivations into head and tail components, leads to infinite loops.
    .take(
      Many(
        memberAccessParser
          .orElse(applicationArgumentsParser)
          .orElse(includeStructLiteral ? Conditional.first(structLiteralParser) : Conditional.second(Fail()))
      )
    )
    .map { (expr: SyntaxNode<Expr<EmptyAnnotation>>, tail: [ExprSyntaxTail]) -> SyntaxNode<Expr<EmptyAnnotation>> in
      tail.reduce(expr) { reducedExpr, tailElement in
        switch tailElement {
        case let .memberAccess(dot, identifier):
          return SyntaxNode(
            leadingTrivia: expr.leadingTrivia,
            content: .init(
              start: reducedExpr.content.start,
              end: identifier.content.end,
              content: .init(.member(.init(base: reducedExpr, dot: dot, member: identifier)))
            )
          )
        case let .applicationArguments(arguments):
          return SyntaxNode(
            leadingTrivia: expr.leadingTrivia,
            content: .init(
              start: reducedExpr.content.start,
              end: arguments.end.content.end,
              content: .init(.application(.init(function: reducedExpr, arguments: arguments)))
            )
          )
        case let .structLiteral(elements):
          return StructLiteral(type: reducedExpr, elements: elements).syntaxNode
            .map(Expr.Payload.structLiteral)
            .map(Expr.init)
        }
      }
    }
    // We're required to give `exprParser()` an explicit type signature, otherwise this won't compile due to mutual
    // recursion with subexpression parsers.
    .eraseToAnyParser()
}

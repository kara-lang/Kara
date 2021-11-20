//
//  Created by Max Desiatov on 21/09/2021.
//

import Parsing

/** `ExprBlock` is not directly representable with any syntax, but is used indirectly as storage for `Closure`,
 `FuncDecl`, and `IfThenElse` bodies.
 */
public struct ExprBlock<A: Annotation> {
  public enum Element {
    case expr(Expr<A>)
    case declaration(Declaration<A>)
  }

  public let openBrace: SyntaxNode<Empty>
  public let elements: [SyntaxNode<Element>]
  public let closeBrace: SyntaxNode<Empty>

  public func addAnnotation<NewAnnotation>(
    expr exprTransform: (Expr<A>) throws -> Expr<NewAnnotation>,
    declaration declarationTransform: (Declaration<A>) throws -> Declaration<NewAnnotation>
  ) rethrows -> ExprBlock<NewAnnotation> {
    try .init(
      openBrace: openBrace,
      elements: elements.map {
        try $0.map {
          switch $0 {
          case let .expr(e):
            return try .expr(exprTransform(e))
          case let .declaration(d):
            return try .declaration(declarationTransform(d))
          }
        }
      },
      closeBrace: closeBrace
    )
  }
}

extension ExprBlock: SyntaxNodeContainer {
  public var start: SyntaxNode<Empty> { openBrace }
  public var end: SyntaxNode<Empty> { closeBrace }
}

let exprBlockElementsParser = Many(
  Lazy { declarationParser }.map { $0.map(ExprBlock.Element.declaration) }
    .orElse(Lazy { exprParser() }.map { $0.map(ExprBlock.Element.expr) }),
  separator: newlineParser
)

let exprBlockParser = openBraceParser
  .take(exprBlockElementsParser)
  .take(closeBraceParser)
  .map { ExprBlock(openBrace: $0, elements: $1, closeBrace: $2).syntaxNode }

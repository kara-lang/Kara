//
//  Created by Max Desiatov on 04/11/2021.
//

import Parsing

/** Enum case declarations can be written in either of these forms:
 1. Without associated values as `case a`
 2. With associated values and no parameter names as `case a(TypeExpr)`
 3. With associated values and parameter names as `case a(x: TypeExpr, y: TypeExpr)`
 where `TypeExpr` is any valid type expression.
 */
public struct EnumCase<A: Annotation> {
  public let modifiers: [SyntaxNode<DeclModifier>]
  public let caseKeyword: SyntaxNode<Empty>
  public let identifier: SyntaxNode<Identifier>
  public let associatedValues: DelimitedSequence<Expr<A>>?

  public func addAnnotation<NewAnnotation: Annotation>(
    _ transform: (Expr<A>) throws -> Expr<NewAnnotation>
  ) rethrows -> EnumCase<NewAnnotation> {
    try .init(
      modifiers: modifiers,
      caseKeyword: caseKeyword,
      identifier: identifier,
      associatedValues: associatedValues?.map(transform)
    )
  }
}

extension EnumCase: SyntaxNodeContainer {
  public var start: SyntaxNode<Empty> { modifiers.first?.empty ?? caseKeyword }
  public var end: SyntaxNode<Empty> { associatedValues?.end ?? identifier.empty }
}

let enumCaseParser =
  Many(declModifierParser)
    .take(Keyword.case.parser)
    .take(identifierParser(requiresLeadingTrivia: true))
    .take(Optional.parser(of: tupleExprParser))
    .map(EnumCase.init)
    .map(\.syntaxNode)

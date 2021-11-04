//
//  Created by Max Desiatov on 04/11/2021.
//

import Parsing

public struct CasePattern<A: Annotation> {
  public let caseKeyword: SyntaxNode<Empty>
  public let bindingKeyword: SyntaxNode<Empty>?
  public let pattern: SyntaxNode<Expr<A>>

  public func addAnnotation<NewAnnotation: Annotation>(
    _ transform: (Expr<A>) throws -> Expr<NewAnnotation>
  ) rethrows -> CasePattern<NewAnnotation> {
    try .init(
      caseKeyword: caseKeyword,
      bindingKeyword: bindingKeyword,
      pattern: pattern.map(transform)
    )
  }
}

let casePatternParser =
  Keyword.case.parser
    .take(Optional.parser(of: Keyword.let.parser))
    .take(Lazy { exprParser })
    .map(CasePattern.init)

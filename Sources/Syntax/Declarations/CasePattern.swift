//
//  Created by Max Desiatov on 04/11/2021.
//

import Parsing

struct CasePattern<A: Annotation> {
  public let caseKeyword: SyntaxNode<Empty>
  public let bindingKeyword: SyntaxNode<Empty>?
  public let pattern: SyntaxNode<Expr<A>>
}

let casePatternParser =
  Keyword.case.parser
    .take(Optional.parser(of: Keyword.let.parser))
    .take(exprParser)
    .map(CasePattern.init)

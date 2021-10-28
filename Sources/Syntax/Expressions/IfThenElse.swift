//
//  Created by Max Desiatov on 04/09/2021.
//

import Parsing

public struct IfThenElse: SyntaxNodeContainer {
  public let ifKeyword: SyntaxNode<Empty>
  public let condition: SyntaxNode<Expr>
  public let thenBlock: ExprBlock

  // FIXME: handle multiple `else if` branches
  public let elseBranch: ElseBranch?

  public var start: SyntaxNode<Empty> { ifKeyword }
  public var end: SyntaxNode<Empty> { elseBranch?.end ?? thenBlock.end }
}

public struct ElseBranch: SyntaxNodeContainer {
  public let elseKeyword: SyntaxNode<Empty>
  public let elseBlock: ExprBlock

  public var start: SyntaxNode<Empty> { elseKeyword }
  public var end: SyntaxNode<Empty> { elseBlock.end }
}

private let elseBranchParser = Parse {
  Keyword.else.parser
  Lazy { exprBlockParser }
}
.map {
  ElseBranch(
    elseKeyword: $0,
    elseBlock: $1.content.content
  )
}

let ifThenElseParser = Parse {
  Keyword.if.parser
  Lazy { exprParser }
  Lazy { exprBlockParser }.map(\.content.content)
  Optional.parser(of: elseBranchParser)
}
.map(IfThenElse.init)
.map(\.syntaxNode)

//
//  Created by Max Desiatov on 22/08/2021.
//

import Parsing

public struct FuncApplication<A: Annotation> {
  public let function: SyntaxNode<Expr<A>>
  public let arguments: DelimitedSequence<Expr<A>>
}

let applicationArgumentsParser =
  delimitedSequenceParser(
    startParser: openParenParser,
    endParser: closeParenParser,
    separatorParser: commaParser,
    elementParser: Lazy { exprParser }
  )
  .map(ExprSyntaxTail.applicationArguments)

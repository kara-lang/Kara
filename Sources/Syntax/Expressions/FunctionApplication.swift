//
//  Created by Max Desiatov on 22/08/2021.
//

import Parsing

public struct FunctionApplication {
  public let function: SyntaxNode<Expr>
  public let arguments: DelimitedSequence<Expr>
}

let applicationArgumentsParser =
  delimitedSequenceParser(
    startParser: openParenParser,
    endParser: closeParenParser,
    elementParser: Lazy { exprParser }
  )
  .map(ExprSyntaxTail.applicationArguments)

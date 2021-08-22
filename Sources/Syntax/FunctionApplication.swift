//
//  Created by Max Desiatov on 22/08/2021.
//

import Parsing

public struct FunctionApplication {
  public let function: SourceRange<Expr>
  public let arguments: [SourceRange<Expr>]
}

let applicationArgumentsParser =
  StatefulWhitespace()
    .ignoreOutput()
    .take(tupleSequenceParser)
    .map(ExprTail.applicationArguments)

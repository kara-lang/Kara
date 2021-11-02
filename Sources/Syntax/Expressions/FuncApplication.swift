//
//  Created by Max Desiatov on 22/08/2021.
//

import Parsing

public struct FuncApplication<A: Annotation> {
  public let function: SyntaxNode<Expr<A>>
  public let arguments: DelimitedSequence<Expr<A>>

  public func addAnnotation<NewAnnotation: Annotation>(
    function functionTransform: (Expr<A>) throws -> Expr<NewAnnotation>,
    argument argumentTransform: (Expr<A>) throws -> Expr<NewAnnotation>
  ) rethrows -> FuncApplication<NewAnnotation> {
    try .init(
      function: function.map(functionTransform),
      arguments: arguments.map(argumentTransform)
    )
  }
}

let applicationArgumentsParser =
  delimitedSequenceParser(
    startParser: openParenParser,
    endParser: closeParenParser,
    separatorParser: commaParser,
    elementParser: Lazy { exprParser }
  )
  .map(ExprSyntaxTail.applicationArguments)

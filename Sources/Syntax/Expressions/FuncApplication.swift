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

/** This special parser is needed to prevent code such as this parsed as a single expression:
 ```
 f
 (1, 2)
 ```
 We expect this to be parsed within an expression block as two separate expessions, first line for the `f` identifier,
 second for the tuple. Without this special parser, the newline separating two separate expressions is consumed as
 leading trivia, as if both lines are a single function application expression.
 */
private let applicationArgumentsStartParser = SyntaxNodeParser(Terminal("("), consumesNewline: false)

let applicationArgumentsParser =
  delimitedSequenceParser(
    startParser: applicationArgumentsStartParser,
    endParser: closeParenParser,
    separatorParser: commaParser,
    elementParser: Lazy { exprParser }
  )
  .map(ExprSyntaxTail.applicationArguments)

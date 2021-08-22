//
//  Created by Max Desiatov on 22/08/2021.
//

public struct FunctionApplication: Equatable {
  public let function: SourceRange<Expr>
  public let arguments: [SourceRange<Expr>]
}

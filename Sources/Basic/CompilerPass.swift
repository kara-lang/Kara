//
//  Created by Max Desiatov on 16/09/2021.
//

public struct CompilerPass<Input, Output> {
  public let transform: (Input) throws -> Output

  public init(transform: @escaping (Input) throws -> Output) {
    self.transform = transform
  }

  public func callAsFunction(_ input: Input) throws -> Output {
    try transform(input)
  }
}

// FIXME: replace with query-based build system
public func | <Input, Intermediate, Output>(
  lhs: CompilerPass<Input, Intermediate>,
  rhs: CompilerPass<Intermediate, Output>
) -> CompilerPass<Input, Output> {
  .init {
    try rhs(lhs($0))
  }
}

//
//  Created by Max Desiatov on 16/09/2021.
//

public struct CompilerPass<Input, Output> {
  public let transform: (Input) -> Output

  public init(transform: @escaping (Input) -> Output) {
    self.transform = transform
  }

  public func callAsFunction(_ input: Input) -> Output {
    transform(input)
  }
}

// FIXME: replace with query-based build system
public func | <Input, Intermediate, Output>(
  lhs: CompilerPass<Input, Intermediate>,
  rhs: CompilerPass<Intermediate, Output>
) -> CompilerPass<Input, Output> {
  .init {
    rhs.transform(lhs.transform($0))
  }
}

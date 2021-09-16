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

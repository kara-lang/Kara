//
//  Created by Max Desiatov on 19/08/2021.
//

import Syntax

extension Literal {
  var defaultType: Type {
    switch self {
    case .int32:
      return .int32
    case .int64:
      return .int64
    case .double:
      return .double
    case .bool:
      return .bool
    case .string:
      return .string
    }
  }
}

extension Expr {
  func infer(
    _ environment: DeclEnvironment = DeclEnvironment()
  ) throws -> Type {
    var system = ConstraintSystem(environment)
    let type = try system.infer(self)

    let solver = Solver(
      substitution: [:],
      system: system
    )
    return try type.apply(solver.solve())
  }
}

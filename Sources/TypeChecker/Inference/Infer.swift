//
//  Created by Max Desiatov on 19/08/2021.
//

import Syntax

extension Expr {
  func infer(
    _ environment: ModuleEnvironment = ModuleEnvironment()
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

//
//  Created by Max Desiatov on 19/08/2021.
//

import Syntax

extension Expr {
  func infer(
    environment: BindingEnvironment = [:],
    members: TypeEnvironment = [:]
  ) throws -> Type {
    var system = ConstraintSystem(
      environment,
      members: members
    )
    let type = try system.infer(self)

    let solver = Solver(
      substitution: [:],
      system: system
    )
    return try type.apply(solver.solve())
  }
}

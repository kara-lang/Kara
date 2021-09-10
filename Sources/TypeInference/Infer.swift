//
//  Created by Max Desiatov on 19/08/2021.
//

import Syntax

extension Expr {
  func infer(
    environment: Environment = [:],
    members: Members = [:]
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

extension String {
  func inferParsedExpr(
    environment: Environment = [:],
    members: Members = [:]
  ) throws -> Type {
    var state = ParsingState(source: self)
    guard let expr = exprParser.parse(&state) else {
      throw ParsingError.unknown(startIndex..<endIndex)
    }

    return try expr.content.infer(environment: environment, members: members)
  }
}

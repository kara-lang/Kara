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

typealias TypeAnnotation = Type

extension TypeAnnotation: Annotation {}

extension Expr where A == EmptyAnnotation {
  func annotate(
    _ environment: ModuleEnvironment
  ) throws -> Expr<TypeAnnotation> {
    var system = ConstraintSystem(environment)
    let annotatedExpr = try system.annotate(expr: self)

    let solver = Solver(
      substitution: [:],
      system: system
    )
    return try annotatedExpr.apply(solver.solve())
  }
}

extension ExprBlock where A == TypeAnnotation {
  func getLastExprType() throws -> Type {
    // An empty block has its type inferred as `.unit`.
    guard !elements.isEmpty else {
      return .unit
    }

    guard case let .expr(last)? = elements.last?.content.content else {
      throw TypeError.noLastExpressionInClosure(start.range.merge(end.range))
    }

    return last.annotation
  }
}

//
//  Created by Max Desiatov on 27/04/2019.
//

import Syntax

/** `Solver` operates on a constraint system, which contains an array of
 `Constraint` values. These constraints are reduced one by one to find a
 suitable `Substitution` that make the constraints consistent with each other.
 `Solver` values are immutable, which allows separate solver iterations to
 operate independently. For example, backtracking is implemented as discarding
 failed `Solver` values and proceeding from the last known consistent iteration
 with new assumptions.
 */
struct Solver {
  private let substitution: TypeSubstitution
  private let system: ConstraintSystem

  init(
    substitution: TypeSubstitution,
    system: ConstraintSystem
  ) {
    self.substitution = substitution
    self.system = system
  }

  private var empty: Solver {
    Solver(
      substitution: [:],
      system: ConstraintSystem(system.environment)
    )
  }

  /** Return a `Substitution` value that satisfies `constraints` within
   the current solver.
   */
  func solve() throws -> TypeSubstitution {
    var system = self.system
    guard let constraint = system.removeFirst() else { return substitution }

    let assumedType: Type
    let actualType: Type
    switch constraint {
    case let .equal(t1, t2):
      let s = try unify(t1, t2)

      system.apply(s.substitution)

      return try Solver(
        substitution: s.substitution.compose(substitution),
        system: s.system.appending(system.constraints)
      ).solve()

    case let .leadingDot(type, identifier):
      guard case let .constructor(typeID, _) = type else {
        fatalError("unhandled leading dot constraint")
      }

      assumedType = try system.lookup(identifier, in: typeID, isStatic: true)
      actualType = type

    case let .member(type, member, memberType):
      actualType = memberType

      switch (type, member) {
      case let (.constructor(typeID, _), .identifier(identifier)):
        // generate new constraints for member lookup
        assumedType = try system.lookup(identifier, in: typeID, isStatic: false)

      case let (.tuple(types), .tupleElement(index)):
        guard (0..<types.count).contains(index) else {
          throw TypeError.tupleIndexOutOfRange(types, addressed: index)
        }
        // generate new constraints for tuple element lookup
        assumedType = types[index]

      default:
        // FIXME: throw meaningful error
        fatalError("unhandled member constraint")
      }
    }

    if case .constructor = assumedType {
      system.prepend(.equal(actualType, assumedType))
    }

    return try Solver(
      substitution: substitution,
      system: system
    ).solve()
  }

  private func unify(_ t1: Type, _ t2: Type) throws -> Solver {
    switch (t1, t2) {
    case let (.arrow(i1, o1), .arrow(i2, o2)):
      let s1 = try unify(.tuple(i1), .tuple(i2))
      let s2 = try unify(o1.apply(s1.substitution), o2.apply(s1.substitution))
      return Solver(
        substitution: s2.substitution.compose(s1.substitution),
        system: s1.system.appending(s2.system.constraints)
      )

    case let (.variable(v), t):
      return try bind(type: t, to: v)

    case let (t, .variable(v)):
      return try bind(type: t, to: v)

    case let (.constructor(id1, args1), .constructor(id2, args2))
      where id1 == id2 && args1 == args2:
      return empty

    case let (.tuple(t1), .tuple(t2)) where t1.count == t2.count:
      return try zip(t1, t2).map {
        // check that we are on the lowest level of the tuple, otherwise
        // call unify on children
        return try unify($0, $1)
      }.reduce(empty) { (s1: Solver, s2: Solver) -> Solver in
        // merge new solver with a solver produced for previous tuple elements
        Solver(
          substitution: s1.substitution.compose(s2.substitution),
          system: s1.system.appending(s2.system.constraints)
        )
      }

    case let (a, b):
      throw TypeError.unificationFailure(a, b)
    }
  }

  /** Bind `type` to a type `variable` with a substitution and return a new
   solver with this substitution. Return an empty solver if `type` is already
   equivalent to the type `variable`.
   */
  private func bind(type: Type, to variable: TypeVariable) throws -> Solver {
    if type == .variable(variable) {
      return empty
    } else if type.occurs(variable) {
      throw TypeError.infiniteType(variable, type)
    }

    return Solver(
      substitution: [variable: type],
      system: empty.system
    )
  }
}

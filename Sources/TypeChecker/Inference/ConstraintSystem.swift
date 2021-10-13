//
//  Created by Max Desiatov on 27/04/2019.
//

import Syntax

enum Constraint {
  /// Type equality constraint
  case equal(Type, Type)

  /** Member constraint representing members of type declarations: functions and
   properties.
   */
  case member(Type, member: Identifier, memberType: Type)
}

struct ConstraintSystem {
  private var typeVariableCount = 0
  private(set) var constraints = [Constraint]()

  private(set) var environment: DeclEnvironment

  init(_ environment: DeclEnvironment) {
    self.environment = environment
  }

  mutating func removeFirst() -> Constraint? {
    constraints.count > 0 ? constraints.removeFirst() : nil
  }

  mutating func prepend(_ constraint: Constraint) {
    constraints.insert(constraint, at: 0)
  }

  func appending(_ constraints: [Constraint]) -> ConstraintSystem {
    var result = self
    result.constraints.append(contentsOf: constraints)
    return result
  }

  mutating func apply(_ sub: Substitution) {
    constraints = constraints.apply(sub)
  }

  /// Temporarily extends the current `self.environment` with `environment` to
  /// infer the type of `inferred` expression. Is used to infer
  /// type of an expression evaluated in a closure.
  private mutating func infer<T>(
    inExtended environment: T,
    _ inferred: Expr
  ) throws -> Type where T: Sequence, T.Element == (Identifier, Scheme) {
    // preserve old environment to be restored after inference in extended
    // environment has finished
    let old = self.environment

    defer { self.environment = old }

    self.environment.insert(environment)

    return try infer(inferred)
  }

  /** Generate a new type variable that can be stored in `constraints`. If
   constraints are consistent and a single solution ca be found, this
   type variable will be resolved to a concrete type with a substitution created
   by a `Solver`.
   */
  private mutating func fresh() -> Type {
    defer { typeVariableCount += 1 }

    return .variable("T\(typeVariableCount)")
  }

  mutating func lookup(
    _ member: Identifier,
    in typeID: TypeIdentifier
  ) throws -> Type {
    guard let environment = environment.types[typeID]?.identifiers else {
      throw TypeError.unknownType(typeID)
    }

    return try lookup(
      member,
      in: environment,
      orThrow: .unknownMember(typeID, member)
    )
  }

  private mutating func lookup(
    _ id: Identifier,
    in bindingEnvironment: BindingEnvironment,
    orThrow error: TypeError
  ) throws -> Type {
    guard let scheme = bindingEnvironment[id] else {
      throw error
    }

    return instantiate(scheme)
  }

  /// Converting a σ type into a τ type by creating fresh names for each type
  /// variable that does not appear in the current typing environment.
  private mutating func instantiate(_ scheme: Scheme) -> Type {
    let substitution = scheme.variables.map { ($0, fresh()) }
    return scheme.type.apply(Dictionary(uniqueKeysWithValues: substitution))
  }

  mutating func infer(_ expr: Expr) throws -> Type {
    switch expr {
    case let .literal(literal):
      return literal.defaultType

    case let .identifier(id):
      return try lookup(id, in: environment.identifiers, orThrow: .unbound(id))

    case let .closure(c):
      let ids = c.parameters.map(\.identifier.content.content)
      let parameters = ids.map { _ in fresh() }
      return try .arrow(
        parameters,
        infer(inExtended: zip(ids, parameters.map { Scheme($0) }), c.body?.content.content ?? .unit)
      )

    case let .application(app):
      let callableType = try infer(app.function.content.content)
      let typeVariable = fresh()
      constraints.append(.equal(
        callableType,
        .arrow(try app.arguments.elementsContent.map { try infer($0) }, typeVariable)
      ))
      return typeVariable

    case let .ifThenElse(ifThenElse):
      let result = try infer(.block(ifThenElse.thenBlock))

      try constraints.append(.equal(infer(ifThenElse.condition.content.content), .bool))

      if let elseBlock = ifThenElse.elseBranch?.elseBlock {
        try constraints.append(.equal(result, infer(.block(elseBlock))))
      } else {
        // A sole `if` branch should have a `.unit` type, to unify with the missing `else` branch, which implicitly
        // evaluates to `.unit`.
        constraints.append(.equal(result, .unit))
      }

      return result

    case let .member(memberAccess):
      switch try infer(memberAccess.base.content.content) {
      case .arrow:
        throw TypeError.arrowMember(memberAccess.member.content.content)

      case let .constructor(typeID, _):
        return try lookup(memberAccess.member.content.content, in: typeID)

      case let .variable(v):
        let memberType = fresh()
        constraints.append(
          .member(.variable(v), member: memberAccess.member.content.content, memberType: memberType)
        )
        return memberType

      case let .tuple(elements):
        if let idx = Int(memberAccess.member.content.content.value) {
          guard (0..<elements.count).contains(idx) else {
            throw TypeError.tupleIndexOutOfRange(
              total: elements.count,
              addressed: idx
            )
          }

          return elements[idx]
        } else {
          throw TypeError.unknownTupleMember(memberAccess.member.content.content)
        }
      }

    case let .tuple(tuple):
      return try .tuple(tuple.elementsContent.map { try infer($0) })

    case let .block(block):
      // Expression blocks should always contain at least one expression and end with an expression.
      guard case let .expr(last) = block.elements.last?.content.content else {
        throw TypeError.noExpressionsInBlock(block.sourceRange)
      }

      return try infer(last)

    case let .structLiteral(structLiteral):
      return structLiteral.type.content.content

    case .type:
      return .type

    case .unit:
      return .unit
    }
  }
}

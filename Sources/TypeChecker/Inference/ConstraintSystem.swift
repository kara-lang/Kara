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
  case member(Type, member: MemberAccess.Member, memberType: Type)
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
    withExtendedBindings bindings: T,
    _ inferred: Expr
  ) throws -> Type where T: Sequence, T.Element == (Identifier, (Expr?, Scheme)) {
    // preserve old environment to be restored after inference in extended
    // environment has finished
    let old = environment

    defer { self.environment = old }

    environment.insert(bindings: bindings)

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
    in typeID: Identifier
  ) throws -> Type {
    guard let environment = environment.types[typeID] else {
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
    in environment: DeclEnvironment,
    orThrow error: TypeError
  ) throws -> Type {
    guard let scheme = environment.bindings[id]?.scheme ?? environment.functions[id]?.scheme else {
      guard environment.types[id] != nil else {
        throw error
      }
      return .type
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
      return try lookup(id, in: environment, orThrow: .unbound(id))

    case let .closure(c):
      let ids = c.parameters.map(\.identifier.content.content)
      let parameters = ids.map { _ in fresh() }
      return try .arrow(
        parameters,
        infer(withExtendedBindings: zip(ids, parameters.map { (nil, Scheme($0)) }), Expr.block(c.exprBlock))
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
      let member = memberAccess.member.content.content

      switch try infer(memberAccess.base.content.content) {
      case .arrow:
        // Function values don't have members.
        throw TypeError.invalidFunctionMember(member)

      case let .constructor(typeID, _):
        // Static member access.
        guard case let .identifier(identifier) = member else {
          throw TypeError.invalidStaticMember(member)
        }
        return try lookup(identifier, in: typeID)

      case let .variable(v):
        let memberType = fresh()
        constraints.append(
          .member(.variable(v), member: member, memberType: memberType)
        )
        return memberType

      case let .tuple(elements):
        guard case let .tupleElement(index) = member else {
          throw TypeError.unknownTupleMember(member)
        }

        guard (0..<elements.count).contains(index) else {
          throw TypeError.tupleIndexOutOfRange(
            elements,
            addressed: index
          )
        }

        return elements[index]
      }

    case let .tuple(tuple):
      return try .tuple(tuple.elementsContent.map { try infer($0) })

    case let .block(block):
      // Expression blocks should always contain at least one expression and end with an expression.
      guard case let .expr(last) = block.elements.last?.content.content else {
        return .unit
      }

      return try infer(last)

    case let .structLiteral(structLiteral):
      let typeExpr = structLiteral.type
      guard let type = try typeExpr.content.content.eval(environment).type else {
        throw TypeError.exprIsNotType(typeExpr.range)
      }

      return type

    case .unit:
      return .unit
    }
  }
}

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
  case member(Type, member: Member, memberType: Type)

  case leadingDot(Type, member: Identifier)
}

struct ConstraintSystem {
  private var typeVariableCount = 0
  private(set) var constraints = [Constraint]()

  private(set) var environment: ModuleEnvironment

  init(_ environment: ModuleEnvironment) {
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
    in typeID: Identifier,
    isStatic: Bool
  ) throws -> Type {
    guard let environment = environment.types[typeID] else {
      throw TypeError.unknownType(typeID)
    }

    return try lookup(
      member,
      schemes: isStatic ? environment.staticMembers : environment.members,
      // Local type environment shadows the top level module environment.
      types: self.environment.types.merging(environment.types) { _, new in new },
      orThrow: .unknownMember(baseTypeID: typeID, .identifier(member))
    )
  }

  private mutating func lookup(
    _ id: Identifier,
    schemes: SchemeEnvironment,
    types: TypeEnvironment,
    orThrow error: TypeError
  ) throws -> Type {
    guard let scheme = schemes.bindings[id]?.scheme ?? schemes.functions[id]?.scheme else {
      guard types[id] != nil else {
        throw error
      }
      return .type
    }

    return instantiate(scheme)
  }

  /// Converting a σ `Scheme` into a τ `Type` by creating fresh names for each type
  /// variable that does not appear in the current typing environment.
  private mutating func instantiate(_ scheme: Scheme) -> Type {
    let substitution = scheme.variables.map { ($0, fresh()) }
    return scheme.type.apply(Dictionary(uniqueKeysWithValues: substitution))
  }

    private func annotate(declaration: Declaration<EmptyAnnotation>) throws -> Declaration<TypeAnnotation> {
        switch declaration {
        case let .binding(b):
            <#code#>
        case let .function(f):
            <#code#>
        case let .struct(s):
            <#code#>
        case let .enum(e):
            <#code#>
        case let .trait(t):
            <#code#>
        }
    }

    private mutating func annotate(block: ExprBlock<EmptyAnnotation>) throws -> ExprBlock<TypeAnnotation> {
        try block.addAnnotation(
            expr: { try annotate(expr: $0) },
            declaration: { try annotate(declaration: $0) }
        )
    }

    /// Temporarily extends the current `self.environment` with `environment` to
    /// infer the type of `closure`, where `bindings` extending the environment represent closure parameters.
    private mutating func annotate(
      closure: Closure<EmptyAnnotation>
    ) throws -> (Closure<TypeAnnotation>, [Type]) {
      // Preserve old environment to be restored after inference in extended environment has finished.
      let old = environment

      defer { self.environment = old }

          let ids = closure.parameters.map(\.identifier.content.content)
          let parameterTypes = ids.map { _ in fresh() }

      environment.schemes.insert(bindings: zip(ids, parameterTypes.map { (nil, Scheme($0)) }))

        return try (closure.addAnnotation(
            parameter: { try annotate(expr: $0) },
            body: { _ in try annotate(block: closure.exprBlock).elements }
        ), parameterTypes)
    }

  mutating func annotate(expr: Expr<EmptyAnnotation>) throws -> Expr<TypeAnnotation> {
    switch expr.payload {
    case let .literal(literal):
        return .init(payload: .literal(literal), annotation: literal.defaultType)

    case let .identifier(id):
        return try .init(
            payload: .identifier(id),
            annotation: lookup(id, schemes: environment.schemes, types: environment.types, orThrow: .unbound(id))
        )

    case let .closure(c):

        let (annotatedClosure, parameterTypes) = try annotate(closure: c)
        return try .init(
            payload: .closure(annotatedClosure),
            annotation: .arrow(
                parameterTypes,
                annotatedClosure.exprBlock.getLastExprType()
            )
        )

    case let .application(app):
      let callableType = try annotate(app.function.content.content)
      let typeVariable = fresh()
      constraints.append(.equal(
        callableType,
        .arrow(try app.arguments.elementsContent.map { try annotate($0) }, typeVariable)
      ))
      return typeVariable

    case let .ifThenElse(ifThenElse):
      let result = try annotate(Expr(.block(ifThenElse.thenBlock)))

      try constraints.append(.equal(annotate(ifThenElse.condition.content.content), .bool))

      if let elseBlock = ifThenElse.elseBranch?.elseBlock {
          try constraints.append(contentsOf: .equal(result, annotate(Expr(.block(elseBlock)))))
      } else {
        // A sole `if` branch should have a `.unit` type, to unify with the missing `else` branch, which implicitly
        // evaluates to `.unit`.
        constraints.append(.equal(result, .unit))
      }

      return result

    case let .member(memberAccess):
      let member = memberAccess.member.content.content

      switch try annotate(memberAccess.base.content.content) {
      case .arrow:
        // Function values don't have members.
        throw TypeError.invalidFunctionMember(member)

      case let .constructor(typeID, _):
        guard case let .identifier(identifier) = member else {
          throw TypeError.unknownMember(baseTypeID: typeID, member)
        }
        return try lookup(identifier, in: typeID, isStatic: false)

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
      return try .tuple(tuple.elementsContent.map { try annotate($0) })

    case let .block(block):
        let annotatedBlock = try annotate(block: block)
        return try .init(
            payload: .block(annotatedBlock)
            annotation: annotatedBlock.getLastExprType()

    case let .structLiteral(structLiteral):
      let typeExpr = structLiteral.type
      guard let type = try typeExpr.content.content.payload.eval(environment).type else {
        throw TypeError.exprIsNotType(typeExpr.range)
      }

      return type

    case .unit:
        return .init(payload: .unit, annotation: .unit)

    case .leadingDot:
      fatalError()
    }
  }
}

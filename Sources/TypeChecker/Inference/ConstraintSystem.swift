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

  private(set) var environment: ModuleEnvironment<EmptyAnnotation>

  init(_ environment: ModuleEnvironment<EmptyAnnotation>) {
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
    schemes: SchemeEnvironment<EmptyAnnotation>,
    types: TypeEnvironment<EmptyAnnotation>,
    orThrow error: TypeError
  ) throws -> Type {
    guard let scheme = schemes.bindings[id]?.scheme ?? schemes.functions[id]?.scheme else {
      guard types[id] != nil || id == "Type" else {
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

  mutating func annotate(funcDecl: FuncDecl<EmptyAnnotation>) throws -> FuncDecl<TypeAnnotation> {
    // Preserve old environment to be restored after inference in extended environment has finished.
    let old = environment

    defer { self.environment = old }

    let ids = funcDecl.parameters.elementsContent.map(\.internalName.content.content)
    let parameterTypes = try funcDecl.parameterTypes(environment)
    environment.schemes.insert(bindings: zip(ids, parameterTypes.map { (nil, Scheme($0)) }))

    return try funcDecl.addAnnotation(
      parameterType: { try annotate(expr: $0) },
      arrow: { try annotate(expr: $0) },
      body: { try annotate(exprBlock: $0) }
    )
  }

  private mutating func annotate(
    declaration: Declaration<EmptyAnnotation>
  ) throws -> Declaration<TypeAnnotation> {
    switch declaration {
    case let .binding(b):
      return try .binding(
        b.addAnnotation(
          typeSignature: { try annotate(expr: $0) },
          value: { try annotate(expr: $0) }
        )
      )

    case let .function(f):
      return try .function(annotate(funcDecl: f))
    case let .struct(s):
      return try .struct(
        s.addAnnotation { try annotate(declaration: $0) }
      )
    case let .enum(e):
      return try .enum(
        e.addAnnotation { try annotate(declaration: $0) }
      )
    case let .trait(t):
      return try .trait(
        t.addAnnotation { try annotate(declaration: $0) }
      )

    case .enumCase:
      fatalError()
    }
  }

  private mutating func annotate(exprBlock: ExprBlock<EmptyAnnotation>) throws -> ExprBlock<TypeAnnotation> {
    try exprBlock.addAnnotation(
      expr: { try annotate(expr: $0) },
      declaration: {
        try environment.insert($0)
        return try annotate(declaration: $0)
      }
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
      body: { try annotate(exprBlock: $0) }
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
      let (annotated, parameterTypes) = try annotate(closure: c)
      return try .init(
        payload: .closure(annotated),
        annotation: .arrow(
          parameterTypes,
          annotated.exprBlock.getLastExprType()
        )
      )

    case let .application(app):
      let annotated = try app.addAnnotation(
        function: { try annotate(expr: $0) },
        argument: { try annotate(expr: $0) }
      )
      let annotatedFunction = annotated.function
      let resultType = fresh()
      constraints.append(.equal(
        annotatedFunction.annotation,
        .arrow(annotated.arguments.elementsContent.map(\.annotation), resultType)
      ))
      return .init(
        payload: .application(annotated),
        annotation: resultType
      )

    case let .ifThenElse(ifThenElse):
      let annotated = try ifThenElse.addAnnotation(
        condition: { try annotate(expr: $0) },
        thenBlock: { try annotate(exprBlock: $0) },
        elseBlock: { try annotate(exprBlock: $0) }
      )
      let resultType = try annotated.thenBlock.getLastExprType()

      constraints.append(.equal(annotated.condition.content.content.annotation, .bool))

      if let elseBlock = annotated.elseBranch?.elseBlock {
        try constraints.append(.equal(resultType, elseBlock.getLastExprType()))
      } else {
        // A sole `if` branch should have a `.unit` type, to unify with the missing `else` branch, which implicitly
        // evaluates to `.unit`.
        constraints.append(.equal(resultType, .unit))
      }

      return .init(
        payload: .ifThenElse(annotated),
        annotation: resultType
      )

    case let .member(memberAccess):
      let annotated = try memberAccess.addAnnotation {
        try annotate(expr: $0)
      }
      let member = memberAccess.member.content.content

      switch annotated.base.annotation {
      case .arrow:
        // Function values don't have members.
        throw TypeError.invalidFunctionMember(member)

      case let .constructor(typeID, _):
        guard case let .identifier(identifier) = member else {
          throw TypeError.unknownMember(baseTypeID: typeID, member)
        }

        let isStatic = typeID == "Type"
        let lookupTypeID: Identifier
        if isStatic {
          guard case let .identifier(baseTypeID) = memberAccess.base.content.content.payload else {
            throw TypeError.unknownMember(baseTypeID: typeID, member)
          }
          lookupTypeID = baseTypeID
        } else {
          lookupTypeID = typeID
        }

        return try .init(
          payload: .member(annotated),
          annotation: lookup(identifier, in: lookupTypeID, isStatic: isStatic)
        )

      case let .variable(v):
        let memberType = fresh()
        constraints.append(
          .member(.variable(v), member: member, memberType: memberType)
        )
        return .init(payload: .member(annotated), annotation: memberType)

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

        return .init(payload: .member(annotated), annotation: elements[index])
      }

    case let .tuple(elements):
      let annotated = try elements.map { try annotate(expr: $0) }
      return .init(
        payload: .tuple(annotated),
        annotation: .tuple(annotated.elementsContent.map(\.annotation))
      )

    case let .block(block):
      let annotatedBlock = try annotate(exprBlock: block)
      return try .init(
        payload: .block(annotatedBlock),
        annotation: annotatedBlock.getLastExprType()
      )

    case let .structLiteral(structLiteral):
      let typeExpr = structLiteral.type
      guard let type = try typeExpr.content.content.eval(environment).type else {
        throw TypeError.exprIsNotType(typeExpr.range)
      }

      let annotated = try structLiteral.addAnnotation(
        type: { try annotate(expr: $0) },
        value: { try annotate(expr: $0) }
      )

      return .init(
        payload: .structLiteral(annotated),
        annotation: type
      )

    case let .leadingDot(l):
      return .init(
        payload: .leadingDot(l),
        annotation: fresh()
      )

    case let .switch(s):
      let annotated = try s.addAnnotation(
        subject: { try annotate(expr: $0) },
        pattern: { try annotate(expr: $0) },
        body: { try annotate(exprBlock: $0) }
      )

      let subjectType = annotated.subject.annotation
      guard let resultType = try annotated.caseBlocks.first?.exprBlock.getLastExprType() else {
        return .init(payload: .switch(annotated), annotation: .unit)
      }

      var resultConstraints = [Constraint]()
      for caseBlock in annotated.caseBlocks {
        // Type of every pattern is the same as the type of the subject.
        constraints.append(.equal(subjectType, caseBlock.casePattern.pattern.annotation))

        // Result type of every case expr block is the ssame for all blocks.
        try resultConstraints.append(.equal(resultType, caseBlock.exprBlock.getLastExprType()))
      }

      constraints.append(
        // Drop the first constraint, which redundantly states that `.equal(resultType, resultType)`
        contentsOf: resultConstraints.dropFirst()
      )

      return .init(
        payload: .switch(annotated),
        annotation: resultType
      )

    case .unit:
      return .init(payload: .unit, annotation: .unit)
    }
  }
}

//
//  Created by Max Desiatov on 27/05/2019.
//

import KIR
import Syntax

/** Schemes are types containing one or more generic variables. A scheme
 explicitly specifies variables bound in the current type, which allows those
 variables to be distinguished from those that were bound in an outer scope.
 */
struct Scheme {
  /** Type containing variables bound in `variables` property.
   */
  let type: Type

  /// Variables bound in the scheme
  let variables: Set<TypeVariable>

  init(
    _ type: Type,
    _ variables: Set<TypeVariable> = .init()
  ) {
    self.type = type
    self.variables = variables
  }
}

/// Helper protocol allowing us to implement `evalToType` on `SyntaxNode` and add `Content: ExprType` constraint on it.
/// Note that `Content == Expr` extension constraint to implement `evalToType` wouldn't work since `Expr` is a generic
/// type.
private protocol ExprType {
  associatedtype A: Annotation

  func eval(_ environment: ModuleEnvironment<A>) throws -> KIRExpr
}

extension Expr: ExprType {}

private extension SyntaxNode where Content: ExprType {
  func evalToType(_ environment: ModuleEnvironment<Content.A>, _ variables: Set<TypeVariable>) throws -> Type {
    let kir = try content.content.eval(environment)
    if let type = try kir.type(environment, variables) {
      return type
    } else if case let .identifier(i) = kir {
      throw TypeError.unbound(i)
    } else {
      throw TypeError.exprIsNotType(range)
    }
  }
}

extension FuncDecl {
  func returnType(_ environment: ModuleEnvironment<A>, _ variables: Set<TypeVariable>) throws -> Type {
    guard let node = arrow?.returns else { return .unit }

    return try node.evalToType(environment, variables)
  }

  func parameterTypes(_ environment: ModuleEnvironment<A>, _ variables: Set<TypeVariable>) throws -> [Type] {
    try parameters.elementsContent.map {
      try $0.type.evalToType(environment, variables)
    }
  }

  func scheme(_ environment: ModuleEnvironment<A>) throws -> Scheme {
    let variables = typeVariables

    return try .init(
      .arrow(parameterTypes(environment, variables), returnType(environment, variables)),
      variables
    )
  }

  var typeVariables: Set<TypeVariable> {
    Set(genericParameters?.elementsContent.map(\.value).map(TypeVariable.init(value:)) ?? [])
  }
}

extension BindingDecl {
  func type(_ environment: ModuleEnvironment<A>) throws -> Type? {
    try typeSignature?.signature.content.content.eval(environment).type(environment)
  }

  func scheme(_ environment: ModuleEnvironment<A>) throws -> Scheme? {
    try type(environment).map { Scheme($0) }
  }
}

extension EnumCase {
  func scheme(enumTypeID: Identifier, _ environment: ModuleEnvironment<A>) throws -> Scheme {
    let selfType = Type.constructor(enumTypeID, [])

    guard
      let associatedValues = try associatedValues?.elementsContent
      .map({ try $0.eval(environment).type(environment)! })
    else {
      // FIXME: support generic enums
      return Scheme(selfType)
    }

    return Scheme(.arrow(associatedValues, selfType))
  }
}

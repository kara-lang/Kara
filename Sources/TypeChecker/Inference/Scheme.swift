//
//  Created by Max Desiatov on 27/05/2019.
//

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
  let variables: [TypeVariable]

  init(
    _ type: Type,
    variables: [TypeVariable] = []
  ) {
    self.type = type
    self.variables = variables
  }
}

extension SyntaxNode where Content == Expr<EmptyAnnotation> {
  func evalToType(_ environment: ModuleEnvironment) throws -> Type {
    let normalForm = try content.content.payload.eval(environment)
    if let type = normalForm.type {
      return type
    } else if case let .identifier(i) = normalForm {
      throw TypeError.unbound(i)
    } else {
      throw TypeError.exprIsNotType(range)
    }
  }
}

extension FuncDecl where A == EmptyAnnotation {
  func returnType(_ environment: ModuleEnvironment) throws -> Type {
    try arrow?.returns.evalToType(environment) ?? .unit
  }

  func parameterTypes(_ environment: ModuleEnvironment) throws -> [Type] {
    try parameters.elementsContent.map { try $0.type.evalToType(environment) }
  }

  func scheme(_ environment: ModuleEnvironment) throws -> Scheme {
    try .init(
      .arrow(parameterTypes(environment), returnType(environment)),
      variables: []
    )
  }
}

extension BindingDecl where A == EmptyAnnotation {
  func type(_ environment: ModuleEnvironment) throws -> Type? {
    try typeSignature?.signature.content.content.payload.eval(environment).type
  }

  func scheme(_ environment: ModuleEnvironment) throws -> Scheme? {
    try type(environment).map { Scheme($0) }
  }
}

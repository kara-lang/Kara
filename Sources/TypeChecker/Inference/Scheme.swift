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

extension SyntaxNode where Content == Expr {
  func evalToType(_ environment: DeclEnvironment) throws -> Type {
    let normalForm = try content.content.eval(environment)
    if let type = normalForm.type {
      return type
    } else if case let .identifier(i) = normalForm {
      throw TypeError.unbound(i)
    } else {
      throw TypeError.exprIsNotType(range)
    }
  }
}

extension FuncDecl {
  func returnType(_ environment: DeclEnvironment) throws -> Type {
    try arrow?.returns.evalToType(environment) ?? .unit
  }

  func parameterTypes(_ environment: DeclEnvironment) throws -> [Type] {
    try parameters.elementsContent.map { try $0.type.evalToType(environment) }
  }

  func scheme(_ environment: DeclEnvironment) throws -> Scheme {
    try .init(
      .arrow(parameterTypes(environment), returnType(environment)),
      variables: []
    )
  }
}

extension BindingDecl {
  func type(_ environment: DeclEnvironment) throws -> Type? {
    try typeAnnotation?.signature.content.content.eval(environment).type
  }

  func scheme(_ environment: DeclEnvironment) throws -> Scheme? {
    try type(environment).map { Scheme($0) }
  }
}

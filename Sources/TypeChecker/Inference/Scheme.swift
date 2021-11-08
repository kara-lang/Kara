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

extension Expr {
  func evalToType(_ environment: ModuleEnvironment<A>, _ range: SourceRange<Empty>) throws -> Type {
    let normalForm = try eval(environment)
    if let type = try normalForm.type(environment) {
      return type
    } else if case let .identifier(i) = normalForm {
      throw TypeError.unbound(i)
    } else {
      throw TypeError.exprIsNotType(range)
    }
  }
}

extension FuncDecl {
  func returnType(_ environment: ModuleEnvironment<A>) throws -> Type {
    guard let node = arrow?.returns else { return .unit }

    return try node.content.content.evalToType(environment, node.range)
  }

  func parameterTypes(_ environment: ModuleEnvironment<A>) throws -> [Type] {
    try parameters.elementsContent.map {
      try $0.type.content.content.evalToType(environment, $0.type.range)
    }
  }

  func scheme(_ environment: ModuleEnvironment<A>) throws -> Scheme {
    try .init(
      .arrow(parameterTypes(environment), returnType(environment)),
      variables: []
    )
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

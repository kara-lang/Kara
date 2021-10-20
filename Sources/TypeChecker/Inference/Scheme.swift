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

extension FuncDecl {
  func returnType(_ environment: DeclEnvironment) throws -> Type {
    if let expr = arrow?.returns {
      if let type = try expr.content.content.eval(environment).type {
        return type
      } else {
        throw TypeError.exprIsNotType(expr.range)
      }
    } else {
      return .unit
    }
  }

  func scheme(_ environment: DeclEnvironment) throws -> Scheme {
    try .init(
      .arrow(parameters.elementsContent.map(\.type.content.content), returnType(environment)),
      variables: genericParameters
    )
  }
}

extension BindingDecl {
  var scheme: Scheme? {
    guard let typeAnnotation = typeAnnotation else {
      return nil
    }
    return .init(typeAnnotation.signature.content.content)
  }
}

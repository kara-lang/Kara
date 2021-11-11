//
//  Created by Max Desiatov on 16/10/2021.
//

import KIR
import Syntax

extension KIRExpr {
  /// Returns a `Type` representation of `self` if it is inferrred to be a type expression. Returns `nil` otherwise.
  func type<A: Annotation>(_ environment: ModuleEnvironment<A>) throws -> Type? {
    switch self {
    case let .tuple(elements):
      return try elements.types(environment).map(Type.tuple)

    case let .typeConstructor(id, args):
      return try args.types(environment).map { .constructor(id, $0) }

    case let .arrow(head, tail):
      guard let headTypes = try head.types(environment), let tailType = try tail.type(environment) else {
        return nil
      }

      return .arrow(headTypes, tailType)

    case let .identifier(i):
      guard environment.schemes[i] != nil else {
        throw TypeError.unbound(i)
      }
      return nil

    case .closure, .literal, .ifThenElse, .structLiteral, .memberAccess, .enumCase, .caseMatch, .application:
      return nil
    }
  }
}

extension Array where Element == KIRExpr {
  func types<A: Annotation>(_ environment: ModuleEnvironment<A>) throws -> [Type]? {
    var elementTypes = [Type]()
    for element in self {
      guard let type = try element.type(environment) else {
        return nil
      }
      elementTypes.append(type)
    }

    return elementTypes
  }
}

//
//  Created by Max Desiatov on 08/10/2021.
//

import Syntax

/** Environment that maps a given `Identifier` to its `Scheme` type signature. */
typealias BindingEnvironment = [Identifier: Scheme]

/** Mapping from a type identifier to an environment with its members. */
typealias TypeEnvironment = [TypeIdentifier: BindingEnvironment]

struct ModuleEnvironment {
  /// Environment of top-level bindings in this module.
  var identifiers: BindingEnvironment

  /// Environment of top-level types in this module.
  var types: TypeEnvironment
}

extension ModuleFile {
  var environment: ModuleEnvironment {
    get throws {
      var identifiers = BindingEnvironment()
      var types = TypeEnvironment()

      for declaration in declarations.map(\.content.content) {
        switch declaration {
        case let .function(f):
          let identifier = f.identifier.content.content
          guard identifiers[identifier] == nil else {
            throw TypeError.funcDeclAlreadyExists(identifier)
          }

          identifiers[identifier] = f.scheme

        case let .binding(b):
          let identifier = b.identifier.content.content
          guard let scheme = b.scheme else {
            throw TypeError.topLevelAnnotationMissing(identifier)
          }

          guard identifiers[identifier] == nil else {
            throw TypeError.bindingDeclAlreadyExists(identifier)
          }

          identifiers[identifier] = scheme

        case let .struct(s):
          guard types[s.name.content] == nil else {
            throw TypeError.typeDeclAlreadyExists(s.name.content)
          }
          types[s.name.content] = [:]

        case .trait:
          continue
        }
      }

      return .init(identifiers: identifiers, types: types)
    }
  }
}

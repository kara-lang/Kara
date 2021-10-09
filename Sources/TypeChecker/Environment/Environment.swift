//
//  Created by Max Desiatov on 08/10/2021.
//

import Syntax

/** Environment that maps a given `Identifier` to its `Scheme` type signature. */
typealias BindingEnvironment = [Identifier: Scheme]

/** Mapping from a type identifier to an environment with its members. */
typealias TypeEnvironment = [TypeIdentifier: Environment]

struct Environment {
  init(identifiers: BindingEnvironment, types: TypeEnvironment) {
    self.identifiers = identifiers
    self.types = types
  }

  init() {
    self.init(identifiers: [:], types: [:])
  }

  /// Environment of top-level bindings in this module.
  var identifiers: BindingEnvironment

  /// Environment of top-level types in this module.
  var types: TypeEnvironment

  mutating func append(_ declaration: Declaration) throws {
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
      types[s.name.content] = try s.environment

    case .trait:
      // FIXME: handle trait declarations
      return
    }
  }
}

extension Environment: ExpressibleByDictionaryLiteral {
  init(dictionaryLiteral elements: (Identifier, Scheme)...) {
    self.init(identifiers: BindingEnvironment(uniqueKeysWithValues: elements), types: [:])
  }
}

extension StructDecl {
  var environment: Environment {
    get throws {
      try declarations.elements.map(\.content.content).reduce(into: Environment()) {
        try $0.append($1)
      }
    }
  }
}

extension ModuleFile {
  var environment: Environment {
    get throws {
      try declarations.map(\.content.content).reduce(into: Environment()) {
        try $0.append($1)
      }
    }
  }
}

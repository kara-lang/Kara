//
//  Created by Max Desiatov on 08/10/2021.
//

import Syntax

struct ModuleEnvironment<A: Annotation> {
  /// Mapping of top-level binding identifiers to their schemes available in this declaration.
  var schemes: SchemeEnvironment<A>

  /// Environment of structs available in this declaration.
  private(set) var types: TypeEnvironment<A>

  init(
    schemes: SchemeEnvironment<A> = .init(),
    types: TypeEnvironment<A> = .init()
  ) {
    self.schemes = schemes
    self.types = types
  }

  /// Create a new module environment for a given module
  /// - Parameter module: `ModuleFile` value to be scanned for declarations that will extend this environment.
  /// - Throws: `TypeError` if type checking fails for any declarations within the module during scanning.
  init(_ module: ModuleFile<A>) throws {
    self = try module.declarations.map(\.content.content).reduce(into: ModuleEnvironment<A>()) {
      try $0.insert($1)
    }
  }

  /// Inserts a given declaration type (and members if appropriate) into this environment.
  /// - Parameter declaration: `Declaration` value that will be recursively scanned to produce nested environments.
  mutating func insert(_ declaration: Declaration<A>) throws {
    switch declaration {
    case let .function(f):
      try schemes.insert(f, self)

    case let .binding(b):
      try schemes.insert(b, self)

    case let .struct(s):
      try types.insert(s, self)

    case let .enum(e):
      try types.insert(e, self)

    case .trait, .enumCase:
      // FIXME: handle trait declarations
      fatalError()
    }
  }

  func verifyContains(_ type: Type) throws {
    switch type {
    case let .arrow(argumentTypes, returnType):
      try argumentTypes.forEach { try verifyContains($0) }
      try verifyContains(returnType)

    case let .constructor(typeID, arguments):
      guard types.structs.keys.contains(typeID) else {
        throw TypeError.unknownType(typeID)
      }
      try arguments.forEach { try verifyContains($0) }

    case .variable:
      // FIXME: handle type variables correctly
      fatalError()

    case let .tuple(elements):
      try elements.forEach { try verifyContains($0) }
    }
  }
}

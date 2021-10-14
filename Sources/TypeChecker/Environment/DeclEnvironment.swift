//
//  Created by Max Desiatov on 08/10/2021.
//

import Syntax

/** Environment that maps a given `Identifier` to its `Scheme` type signature. */
typealias BindingEnvironment = [Identifier: Scheme]

/** Mapping from a type identifier to an environment with its members. */
typealias TypeEnvironment = [TypeIdentifier: DeclEnvironment]

struct DeclEnvironment {
  init(identifiers: BindingEnvironment, types: TypeEnvironment) {
    self.identifiers = identifiers
    self.types = types
  }

  init() {
    self.init(identifiers: [:], types: [:])
  }

  /// Environment of top-level bindings in this module.
  private(set) var identifiers: BindingEnvironment

  /// Environment of top-level types in this module.
  private(set) var types: TypeEnvironment

  /// Inserts a given declaration type (and members if appropriate) into this environment.
  /// - Parameter declaration: `Declaration` value to use for inserting intto the environment
  mutating func insert(_ declaration: Declaration) throws {
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
      let typeIdentifier = s.identifier.content.content

      guard types[typeIdentifier] == nil else {
        throw TypeError.typeDeclAlreadyExists(typeIdentifier)
      }
      types[typeIdentifier] = try s.environment

    case let .enum(e):
      let typeIdentifier = e.identifier.content.content
      guard types[typeIdentifier] == nil else {
        throw TypeError.typeDeclAlreadyExists(typeIdentifier)
      }
      types[typeIdentifier] = try e.environment

    case .trait:
      // FIXME: handle trait declarations
      return
    }
  }

  /// Inserts a given function parameter into this environment.
  /// - Parameter parameter: `FuncDecl.Parameter` value to use for inserting intto the environment
  mutating func insert(_ parameter: FuncDecl.Parameter) {
    identifiers[parameter.internalName.content.content] = .init(parameter.type.content.content)
  }

  mutating func insert<T>(_ sequence: T) where T: Sequence, T.Element == (Identifier, Scheme) {
    for (id, scheme) in sequence {
      identifiers[id] = scheme
    }
  }

  func verifyContains(_ type: Type) throws {
    switch type {
    case let .arrow(argumentTypes, returnType):
      try argumentTypes.forEach { try verifyContains($0) }
      try verifyContains(returnType)

    case let .constructor(typeID, arguments):
      guard types.keys.contains(typeID) else {
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

extension DeclEnvironment: ExpressibleByDictionaryLiteral {
  init(dictionaryLiteral elements: (Identifier, Scheme)...) {
    self.init(identifiers: BindingEnvironment(uniqueKeysWithValues: elements), types: [:])
  }
}

extension StructDecl {
  var environment: DeclEnvironment {
    get throws {
      try declarations.elements.map(\.content.content).reduce(into: DeclEnvironment()) {
        try $0.insert($1)
      }
    }
  }
}

extension EnumDecl {
  var environment: DeclEnvironment {
    get throws {
      try declarations.elements.map(\.content.content).reduce(into: DeclEnvironment()) {
        try $0.insert($1)
      }
    }
  }
}

extension ModuleFile {
  var environment: DeclEnvironment {
    get throws {
      try declarations.map(\.content.content).reduce(into: DeclEnvironment()) {
        try $0.insert($1)
      }
    }
  }
}

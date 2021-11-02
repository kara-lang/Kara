//
//  Created by Max Desiatov on 08/10/2021.
//

import Syntax

/** Mapping from a type identifier to an environment with its members. */
typealias TypeEnvironment = [Identifier: MemberEnvironment]

typealias StructLiteralEnvironment = [Identifier: Set<StructLiteralField>]

struct StructLiteralField: Hashable {
  let identifier: SourceRange<Identifier>
  let typeAnnotation: NormalForm
}

struct ModuleEnvironment {
  /// Mapping of identifiers to their schemes available in this declaration.
  var schemes: SchemeEnvironment

  /// Environment of types available in this declaration.
  private(set) var types: TypeEnvironment

  /// Environment of struct literals available in this declaration.
  private(set) var structLiterals: StructLiteralEnvironment

  init(
    schemes: SchemeEnvironment = .init(),
    types: TypeEnvironment = [:],
    structLiterals: StructLiteralEnvironment = [:]
  ) {
    self.schemes = schemes
    self.types = types
    self.structLiterals = structLiterals
  }

  /// Create a new module environment for a given module
  /// - Parameter module: `ModuleFile` value to be scanned for declarations that will extend this environment.
  /// - Throws: `TypeError` if type checking fails for any declarations within the module during scanning.
  init(_ module: ModuleFile<EmptyAnnotation>) throws {
    self = try module.declarations.map(\.content.content).reduce(into: ModuleEnvironment()) {
      try $0.insert($1)
    }
  }

  /// Inserts a given declaration type (and members if appropriate) into this environment.
  /// - Parameter declaration: `Declaration` value that will be recursively scanned to produce nested environments.
  mutating func insert(_ declaration: Declaration<EmptyAnnotation>) throws {
    switch declaration {
    case let .function(f):
      try schemes.insert(f, self)

    case let .binding(b):
      try schemes.insert(b, self)

    case let .struct(s):
      let typeIdentifier = s.identifier.content.content

      guard types[typeIdentifier] == nil else {
        throw TypeError.typeDeclAlreadyExists(typeIdentifier)
      }
      // Add an empty environment first to allow members to reference own type.
      types[typeIdentifier] = MemberEnvironment()
      types[typeIdentifier] = try s.extend(self)

    case let .enum(e):
      let typeIdentifier = e.identifier.content.content
      guard types[typeIdentifier] == nil else {
        throw TypeError.typeDeclAlreadyExists(typeIdentifier)
      }
      types[typeIdentifier] = try e.extend(self)

    case .trait:
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

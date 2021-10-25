//
//  Created by Max Desiatov on 08/10/2021.
//

import Syntax

/// Environment that maps available identifiers to their `Scheme` signatures together with optional definitions.
struct SchemeEnvironment {
  typealias Bindings = [Identifier: (value: Expr?, scheme: Scheme)]
  typealias Functions = [Identifier: (body: ExprBlock?, scheme: Scheme)]

  init(bindings: Bindings = .init(), functions: Functions = .init()) {
    self.bindings = bindings
    self.functions = functions
  }

  fileprivate(set) var bindings: Bindings
  fileprivate(set) var functions: Functions
}

/** Mapping from a type identifier to an environment with its members. */
typealias TypeEnvironment = [Identifier: DeclEnvironment]

struct MemberEnvironment {
  /** Members available on implicitly declared `self` in the current scope, or on a given value of such type
    in any location that has the type available in scope.
   */
  let members: SchemeEnvironment

  /** Members available on implicitly declared `Self` type in the current scope, via leading dot
   expressions, or via fully qualified type name where such type is available in scope.
   */
  let staticMembers: SchemeEnvironment

  /** Member types on implicitly declared `Self` type in the current scope, or via fully qualified type
   name where such type is available in scope.
   */
  let types: TypeEnvironment
}

typealias StructLiteralEnvironment = [Identifier: Set<StructLiteralField>]

struct StructLiteralField: Hashable {
  let identifier: SourceRange<Identifier>
  let typeAnnotation: NormalForm
}

struct DeclEnvironment {
  init(
    schemes: SchemeEnvironment = .init(),
    types: TypeEnvironment = [:],
    structLiterals: StructLiteralEnvironment = [:]
  ) {
    self.schemes = schemes
    self.types = types
    self.structLiterals = structLiterals
  }

  /// Mapping of identifiers to their schemes available in this declaration.
  private(set) var schemes: SchemeEnvironment

  /// Environment of types available in this declaration.
  private(set) var types: TypeEnvironment

  /// Environment of struct literals available in this declaration.
  private(set) var structLiterals: StructLiteralEnvironment

  /// Inserts a given declaration type (and members if appropriate) into this environment.
  /// - Parameter declaration: `Declaration` value to use for inserting intto the environment
  mutating func insert(_ declaration: Declaration) throws {
    switch declaration {
    case let .function(f):
      let identifier = f.identifier.content.content
      guard schemes.functions[identifier] == nil else {
        throw TypeError.funcDeclAlreadyExists(identifier)
      }

      schemes.functions[identifier] = try (f.body, f.scheme(self))

    case let .binding(b):
      let identifier = b.identifier.content.content
      guard let scheme = try b.scheme(self) else {
        throw TypeError.topLevelAnnotationMissing(identifier)
      }

      guard schemes.bindings[identifier] == nil else {
        throw TypeError.bindingDeclAlreadyExists(identifier)
      }

      schemes.bindings[identifier] = (b.value?.expr.content.content, scheme)

    case let .struct(s):
      let typeIdentifier = s.identifier.content.content

      guard types[typeIdentifier] == nil else {
        throw TypeError.typeDeclAlreadyExists(typeIdentifier)
      }
      let environment = try s.extend(self)
      types[typeIdentifier] = environment

    case let .enum(e):
      let typeIdentifier = e.identifier.content.content
      guard types[typeIdentifier] == nil else {
        throw TypeError.typeDeclAlreadyExists(typeIdentifier)
      }
      types[typeIdentifier] = try e.extend(self)

    case .trait:
      // FIXME: handle trait declarations
      return
    }
  }

  mutating func insert<T>(bindings sequence: T) where T: Sequence, T.Element == (Identifier, (Expr?, Scheme)) {
    for (id, (value, scheme)) in sequence {
      schemes.bindings[id] = (value, scheme)
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

extension StructDecl {
  func extend(_ environment: DeclEnvironment) throws -> DeclEnvironment {
    try declarations.elements.map(\.content.content).reduce(into: environment) {
      try $0.insert($1)
    }
  }
}

extension EnumDecl {
  func extend(_ environment: DeclEnvironment) throws -> DeclEnvironment {
    try declarations.elements.map(\.content.content).reduce(into: environment) {
      try $0.insert($1)
    }
  }
}

extension ModuleFile {
  func extend(_ environment: DeclEnvironment) throws -> DeclEnvironment {
    try declarations.map(\.content.content).reduce(into: environment) {
      try $0.insert($1)
    }
  }
}

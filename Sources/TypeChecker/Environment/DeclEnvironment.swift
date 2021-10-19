//
//  Created by Max Desiatov on 08/10/2021.
//

import Syntax

/** Environment that maps a given binding `Identifier` to its declaration and `Scheme` signature. */
typealias BindingEnvironment = [Identifier: (value: Expr?, scheme: Scheme)]

/** Environment that maps a given function `Identifier` to its declaration and `Scheme` signature. */
typealias FunctionEnvironment = [Identifier: (body: ExprBlock?, scheme: Scheme)]

/** Mapping from a type identifier to an environment with its members. */
typealias TypeEnvironment = [Identifier: DeclEnvironment]

typealias StructLiteralEnvironment = [Identifier: Set<StructLiteralField>]

struct StructLiteralField: Hashable {
  let identifier: SourceRange<Identifier>
  let typeAnnotation: BindingDecl.TypeAnnotation
}

struct DeclEnvironment {
  init(
    bindings: BindingEnvironment = [:],
    functions: FunctionEnvironment = [:],
    types: TypeEnvironment = [:],
    structLiterals: StructLiteralEnvironment = [:]
  ) {
    self.bindings = bindings
    self.functions = functions
    self.types = types
    self.structLiterals = structLiterals
  }

  /// Environment of bindings available in this declaration.
  private(set) var bindings: BindingEnvironment

  /// Environment of functions available in this declaration.
  private(set) var functions: FunctionEnvironment

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
      guard functions[identifier] == nil else {
        throw TypeError.funcDeclAlreadyExists(identifier)
      }

      functions[identifier] = (f.body, f.scheme)

    case let .binding(b):
      let identifier = b.identifier.content.content
      guard let scheme = b.scheme else {
        throw TypeError.topLevelAnnotationMissing(identifier)
      }

      guard bindings[identifier] == nil else {
        throw TypeError.bindingDeclAlreadyExists(identifier)
      }

      bindings[identifier] = (b.value?.expr.content.content, scheme)

    case let .struct(s):
      let typeIdentifier = s.identifier.content.content

      guard types[typeIdentifier] == nil else {
        throw TypeError.typeDeclAlreadyExists(typeIdentifier)
      }
      let environment = try s.environment
      types[typeIdentifier] = environment

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
    bindings[parameter.internalName.content.content] = (nil, .init(parameter.type.content.content))
  }

  mutating func insert<T>(bindings sequence: T) where T: Sequence, T.Element == (Identifier, (Expr?, Scheme)) {
    for (id, (value, scheme)) in sequence {
      bindings[id] = (value, scheme)
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

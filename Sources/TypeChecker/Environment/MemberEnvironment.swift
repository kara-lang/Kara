//
//  Created by Max Desiatov on 25/10/2021.
//

import Syntax

struct MemberEnvironment<A: Annotation> {
  init(
    members: SchemeEnvironment<A> = .init(),
    staticMembers: SchemeEnvironment<A> = .init(),
    types: TypeEnvironment<A> = [:]
  ) {
    self.members = members
    self.staticMembers = staticMembers
    self.types = types
  }

  /** Members available on implicitly declared `self` in the current scope, or on a given value of such type
    in any location that has the type available in scope.
   */
  var members: SchemeEnvironment<A>

  /** Members available on implicitly declared `Self` type in the current scope, via leading dot
   expressions, or via fully qualified type name where such type is available in scope.
   */
  var staticMembers: SchemeEnvironment<A>

  /** Member types on implicitly declared `Self` type in the current scope, or via fully qualified type
   name where such type is available in scope.
   */
  var types: TypeEnvironment<A>

  /// Inserts a given declaration type (and members if appropriate) into this environment.
  /// - Parameter declaration: `Declaration` value that will be recursively scanned to produce nested environments.
  mutating func insert(_ declaration: Declaration<A>, _ topLevel: ModuleEnvironment<A>) throws {
    switch declaration {
    case let .function(f):
      if f.isStatic {
        try staticMembers.insert(f, topLevel)
      } else {
        try members.insert(f, topLevel)
      }

    case let .binding(b):
      if b.isStatic {
        try staticMembers.insert(b, topLevel)
      } else {
        try members.insert(b, topLevel)
      }

    case let .struct(s):
      let typeIdentifier = s.identifier.content.content

      guard types[typeIdentifier] == nil else {
        throw TypeError.typeDeclAlreadyExists(typeIdentifier)
      }
      types[typeIdentifier] = try s.extend(topLevel)

    case let .enum(e):
      let typeIdentifier = e.identifier.content.content
      guard types[typeIdentifier] == nil else {
        throw TypeError.typeDeclAlreadyExists(typeIdentifier)
      }
      types[typeIdentifier] = try e.extend(topLevel)

    case .trait, .enumCase:
      // FIXME: handle trait declarations
      fatalError()
    }
  }
}

extension StructDecl {
  func extend(_ topLevel: ModuleEnvironment<A>) throws -> MemberEnvironment<A> {
    try declarations.elements.map(\.content.content).reduce(into: MemberEnvironment<A>()) {
      try $0.insert($1, topLevel)
    }
  }
}

extension EnumDecl {
  func extend(_ topLevel: ModuleEnvironment<A>) throws -> MemberEnvironment<A> {
    try declarations.elements.map(\.content.content).reduce(into: MemberEnvironment<A>()) {
      try $0.insert($1, topLevel)
    }
  }
}

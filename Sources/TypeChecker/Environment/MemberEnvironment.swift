//
//  Created by Max Desiatov on 25/10/2021.
//

import Syntax

struct MemberEnvironment<A: Annotation> {
  init(
    valueMembers: SchemeEnvironment<A> = .init(),
    staticMembers: SchemeEnvironment<A> = .init(),
    types: TypeEnvironment<A> = .init()
  ) {
    self.valueMembers = valueMembers
    self.staticMembers = staticMembers
    self.types = types
  }

  /** Members available on implicitly declared `self` in the current scope, or on a given value of such type
    in any location that has the type available in scope.
   */
  var valueMembers: SchemeEnvironment<A>

  /** Members available on implicitly declared `Self` type in the current scope, via leading dot
   expressions, or via fully qualified type name where such type is available in scope.
   */
  var staticMembers: SchemeEnvironment<A>

  /** Member types on implicitly declared `Self` type in the current scope.
   */
  var types: TypeEnvironment<A>

  /// Inserts a given declaration type (and members if appropriate) into this environment.
  /// - Parameter declaration: `Declaration` value that will be recursively scanned to produce nested environments.
  mutating func insert(
    _ declaration: Declaration<A>,
    container: Declaration<A>,
    _ topLevel: ModuleEnvironment<A>
  ) throws {
    switch (declaration, container) {
    case let (.function(f), _):
      if f.isStatic {
        try staticMembers.insert(func: f, topLevel)
      } else {
        try valueMembers.insert(func: f, topLevel)
      }

    case let (.binding(b), .struct):
      if b.isStatic {
        try staticMembers.insert(binding: b, topLevel)
      } else {
        try valueMembers.insert(binding: b, topLevel)
      }

    case (.binding, _):
      fatalError()

    case let (.struct(s), _):
      try types.insert(struct: s, topLevel)

    case let (.enum(e), _):
      try types.insert(enum: e, topLevel)

    case let (.enumCase(enumCase), .enum(enumDecl)):
      try staticMembers.insert(enumCase: enumCase, enumTypeID: enumDecl.identifier.content.content, topLevel)

    case let (.enumCase(enumCase), _):
      throw TypeError.enumCaseOutsideOfEnum(enumCase.identifier.content)

    case (.trait, _):
      // FIXME: handle trait declarations
      fatalError()
    }
  }
}

extension StructDecl {
  func extend(_ topLevel: ModuleEnvironment<A>) throws -> StructEnvironment<A> {
    try .init(members: declarations.elements.map(\.content.content).reduce(into: MemberEnvironment<A>()) {
      try $0.insert($1, container: .struct(self), topLevel)
    })
  }
}

extension EnumDecl {
  func extend(_ topLevel: ModuleEnvironment<A>) throws -> EnumEnvironment<A> {
    var result = EnumEnvironment<A>()
    for declaration in declarations.elements.map(\.content.content) {
      try result.insert(declaration, container: .enum(self), topLevel)
    }
    return result
  }
}

//
//  Created by Max Desiatov on 07/11/2021.
//

import Syntax

/** Mapping from a struct identifier to an environment with its members. */
typealias StructDeclEnvironment<A: Annotation> = [Identifier: StructEnvironment<A>]

/** Mapping from an enum identifier to an environment with its members. */
typealias EnumDeclEnvironment<A: Annotation> = [Identifier: EnumEnvironment<A>]

struct TypeEnvironment<A: Annotation> {
  init(structs: StructDeclEnvironment<A> = [:], enums: EnumDeclEnvironment<A> = [:]) {
    self.structs = structs
    self.enums = enums
  }

  /// Environment of structs available in this declaration.
  private(set) var structs: StructDeclEnvironment<A>

  /// Environment of enums available in this declaration.
  private(set) var enums: EnumDeclEnvironment<A>

  func contains(_ typeIdentifier: Identifier) -> Bool {
    structs[typeIdentifier] != nil || enums[typeIdentifier] != nil
  }

  func shadow(with local: TypeEnvironment<A>) -> TypeEnvironment {
    // Local type environment shadows the top level module environment.
    .init(
      structs: structs.merging(local.structs) { _, new in new },
      enums: enums.merging(local.enums) { _, new in new }
    )
  }

  mutating func insert(_ s: StructDecl<A>, _ topLevel: ModuleEnvironment<A>) throws {
    let typeIdentifier = s.identifier.content.content

    guard !contains(typeIdentifier) else {
      throw TypeError.typeDeclAlreadyExists(typeIdentifier)
    }
    // Add an empty environment first to allow members to reference own type.
    structs[typeIdentifier] = .init(members: MemberEnvironment<A>())
    structs[typeIdentifier] = try s.extend(topLevel.shadow(with: self))
  }

  mutating func insert(_ e: EnumDecl<A>, _ topLevel: ModuleEnvironment<A>) throws {
    let typeIdentifier = e.identifier.content.content
    guard !contains(typeIdentifier) else {
      throw TypeError.typeDeclAlreadyExists(typeIdentifier)
    }
    // Add an empty environment first to allow members to reference own type.
    enums[typeIdentifier] = .init(members: MemberEnvironment<A>())
    enums[typeIdentifier] = try e.extend(topLevel.shadow(with: self))
  }
}

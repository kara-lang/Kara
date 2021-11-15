//
//  Created by Max Desiatov on 07/11/2021.
//

import KIR
import Syntax

/// Mapping from an enum case identifier to its tag and an array of types of its associated values.
typealias EnumCases = [Identifier: (tag: Int, arguments: [KIRExpr])]

@dynamicMemberLookup
struct EnumEnvironment<A: Annotation> {
  init(enumCases: EnumCases = .init(), members: MemberEnvironment<A> = .init()) {
    self.enumCases = enumCases
    self.members = members
  }

  private(set) var enumCases: EnumCases

  private(set) var members: MemberEnvironment<A>

  subscript<T>(dynamicMember keyPath: KeyPath<MemberEnvironment<A>, T>) -> T {
    members[keyPath: keyPath]
  }

  /// Inserts a given declaration type (and members if appropriate) into this environment.
  /// - Parameter declaration: `Declaration` value that will be recursively scanned to produce nested environments.
  mutating func insert(
    _ declaration: Declaration<A>,
    container: Declaration<A>,
    _ topLevel: ModuleEnvironment<A>
  ) throws {
    guard case let .enumCase(e) = declaration else {
      return try members.insert(declaration, container: container, topLevel)
    }

    guard e.modifiers.isEmpty else {
      throw TypeError.enumCaseModifiers(e.identifier.content)
    }

    enumCases[e.identifier.content.content] = try (enumCases.count, e.associatedValues?.elementsContent.map {
      try $0.eval(topLevel)
    } ?? [])

    // Insert the enum case declaration as a static member to allow type inference to work it.
    try members.insert(declaration, container: container, topLevel)
  }
}

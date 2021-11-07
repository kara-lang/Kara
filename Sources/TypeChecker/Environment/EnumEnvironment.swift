//
//  Created by Max Desiatov on 07/11/2021.
//

import Syntax

/// Mapping from an enum case identifier to an array of types of its associated values.
typealias EnumCases = [SourceRange<Identifier>: [NormalForm]]

@dynamicMemberLookup
struct EnumEnvironment<A: Annotation> {
  init(enumCases: EnumCases = [:], members: MemberEnvironment<A> = .init()) {
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
  mutating func insert(_ declaration: Declaration<A>, _ topLevel: ModuleEnvironment<A>) throws {
    guard case let .enumCase(e) = declaration else {
      return try members.insert(declaration, topLevel)
    }

    guard e.modifiers.isEmpty else {
      throw TypeError.enumCaseModifiers(e.identifier.content)
    }

    enumCases[e.identifier.content] = try e.associatedValues?.elementsContent.map {
      try $0.eval(topLevel)
    } ?? []
  }
}

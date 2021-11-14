//
//  Created by Max Desiatov on 25/10/2021.
//

import Syntax

/// Environment that maps available identifiers to their `Scheme` signatures together with optional definitions.
struct SchemeEnvironment<A: Annotation> {
  typealias Bindings = [Identifier: (value: Expr<A>?, scheme: Scheme)]
  typealias Functions = [Identifier: (parameters: [Identifier], body: ExprBlock<A>?, scheme: Scheme)]

  init(bindings: Bindings = .init(), functions: Functions = .init()) {
    self.bindings = bindings
    self.functions = functions
  }

  private(set) var bindings: Bindings
  private(set) var functions: Functions

  subscript(_ identifier: Identifier) -> Scheme? {
    bindings[identifier]?.scheme ?? functions[identifier]?.scheme
  }

  func verifyIdentifierIsFree(_ identifier: Identifier) throws {
    guard functions[identifier] == nil else {
      throw TypeError.funcDeclAlreadyExists(identifier)
    }
    guard bindings[identifier] == nil else {
      throw TypeError.bindingDeclAlreadyExists(identifier)
    }
  }

  mutating func insert(binding b: BindingDecl<A>, _ topLevel: ModuleEnvironment<A>) throws {
    let identifier = b.identifier.content.content
    try verifyIdentifierIsFree(identifier)

    guard let scheme = try b.scheme(topLevel) else {
      if let typeSignature = b.typeSignature {
        throw TypeError.exprIsNotType(typeSignature.signature.range)
      } else {
        throw TypeError.topLevelAnnotationMissing(identifier)
      }
    }

    bindings[identifier] = (b.value?.expr.content.content, scheme)
  }

  mutating func insert(func f: FuncDecl<A>, _ topLevel: ModuleEnvironment<A>) throws {
    let identifier = f.identifier.content.content
    try verifyIdentifierIsFree(identifier)

    functions[identifier] = try (
      f.parameters.elementsContent.map(\.internalName.content.content),
      f.body,
      f.scheme(topLevel)
    )
  }

  /// Extends given environment with new bindings. This function
  /// is intended to be only used when processing function or closure scope. Tt doesn't throw when an identifier
  /// already exists in outer scope since it allows identifier shadowing.
  /// - Parameter sequence: a sequence of identifier bindings and their corresponding schemes.
  mutating func insert<T>(bindings sequence: T) where T: Sequence, T.Element == (Identifier, Scheme) {
    for (identifier, scheme) in sequence {
      bindings[identifier] = (nil, scheme)
    }
  }

  mutating func insert(enumCase e: EnumCase<A>, enumTypeID: Identifier, _ topLevel: ModuleEnvironment<A>) throws {
    let identifier = e.identifier.content.content
    try verifyIdentifierIsFree(identifier)

    bindings[identifier] = try (nil, e.scheme(enumTypeID: enumTypeID, topLevel))
  }
}

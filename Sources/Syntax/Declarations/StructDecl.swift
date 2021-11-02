//
//  Created by Max Desiatov on 11/08/2021.
//

import Parsing

public struct StructDecl<A: Annotation> {
  public let modifiers: [SyntaxNode<DeclModifier>]
  public let structKeyword: SyntaxNode<Empty>
  public let identifier: SyntaxNode<Identifier>
  public let declarations: SyntaxNode<DeclBlock<A>>

  public func addAnnotation<NewAnnotation: Annotation>(
    _ transform: (Declaration<A>) throws -> Declaration<NewAnnotation>
  ) rethrows -> StructDecl<NewAnnotation> {
    try .init(
      modifiers: modifiers,
      structKeyword: structKeyword,
      identifier: identifier,
      declarations: declarations.map { try $0.addAnnotation(transform) }
    )
  }
}

extension StructDecl: SyntaxNodeContainer {
  public var start: SyntaxNode<Empty> { modifiers.first?.empty ?? structKeyword }
  public var end: SyntaxNode<Empty> { declarations.end }
}

let structParser =
  Many(declModifierParser)
    .take(Keyword.struct.parser)
    .take(identifierParser(requiresLeadingTrivia: true))
    .take(declBlockParser)
    // FIXME: generic parameters
    .map { StructDecl(modifiers: $0, structKeyword: $1, identifier: $2, declarations: $3) }
    .map(\.syntaxNode)

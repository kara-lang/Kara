//
//  Created by Max Desiatov on 03/09/2021.
//

import Parsing

public struct TraitDecl<A: Annotation> {
  public let modifiers: [SyntaxNode<DeclModifier>]
  public let traitKeyword: SyntaxNode<Empty>
  public let identifier: SyntaxNode<Identifier>
  public let declarations: SyntaxNode<DeclBlock<A>>

  public func addAnnotation<NewAnnotation: Annotation>(
    _ transform: (Declaration<A>) throws -> Declaration<NewAnnotation>
  ) rethrows -> TraitDecl<NewAnnotation> {
    try .init(
      modifiers: modifiers,
      traitKeyword: traitKeyword,
      identifier: identifier,
      declarations: declarations.map { try $0.addAnnotation(transform) }
    )
  }
}

extension TraitDecl: SyntaxNodeContainer {
  public var start: SyntaxNode<Empty> { traitKeyword }

  public var end: SyntaxNode<Empty> { declarations.end }
}

let traitParser =
  Many(declModifierParser)
    .take(Keyword.trait.parser)
    .take(identifierParser(requiresLeadingTrivia: true))
    .take(declBlockParser)
    .map(TraitDecl.init)
    .map(\.syntaxNode)

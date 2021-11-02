//
//  Created by Max Desiatov on 13/10/2021.
//

import Parsing

public struct EnumDecl<A: Annotation> {
  public let modifiers: [SyntaxNode<DeclModifier>]
  public let enumKeyword: SyntaxNode<Empty>
  public let identifier: SyntaxNode<Identifier>
  public let declarations: SyntaxNode<DeclBlock<A>>

  public func addAnnotation<NewAnnotation: Annotation>(
    _ transform: (Declaration<A>) throws -> Declaration<NewAnnotation>
  ) rethrows -> EnumDecl<NewAnnotation> {
    try .init(
      modifiers: modifiers,
      enumKeyword: enumKeyword,
      identifier: identifier,
      declarations: declarations.map { try $0.addAnnotation(transform) }
    )
  }
}

extension EnumDecl: SyntaxNodeContainer {
  public var start: SyntaxNode<Empty> { modifiers.first?.empty ?? enumKeyword }
  public var end: SyntaxNode<Empty> { declarations.end }
}

let enumParser =
  Many(declModifierParser)
    .take(Keyword.enum.parser)
    .take(identifierParser(requiresLeadingTrivia: true))
    .take(declBlockParser)
    // FIXME: generic parameters
    .map { EnumDecl(modifiers: $0, enumKeyword: $1, identifier: $2, declarations: $3) }
    .map(\.syntaxNode)

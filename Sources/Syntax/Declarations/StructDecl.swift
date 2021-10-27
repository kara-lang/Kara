//
//  Created by Max Desiatov on 11/08/2021.
//

import Parsing

public struct StructDecl {
  public let modifiers: [SyntaxNode<DeclModifier>]
  public let structKeyword: SyntaxNode<Empty>
  public let identifier: SyntaxNode<Identifier>
  public let declarations: SyntaxNode<DeclBlock>
}

extension StructDecl: SyntaxNodeContainer {
  public var start: SyntaxNode<Empty> { modifiers.first?.empty ?? structKeyword }
  public var end: SyntaxNode<Empty> { declarations.end }
}

extension StructDecl: CustomStringConvertible {
  public var description: String {
    "struct \(identifier) {}"
  }
}

let structParser =
  Many(declModifierParser)
    .take(Keyword.struct.parser)
    .take(identifierParser(requiresLeadingTrivia: true))
    .take(declBlockParser)
    // FIXME: generic parameters
    .map { StructDecl(modifiers: $0, structKeyword: $1, identifier: $2, declarations: $3) }
    .map(\.syntaxNode)

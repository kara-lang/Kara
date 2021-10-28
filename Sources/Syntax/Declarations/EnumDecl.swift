//
//  Created by Max Desiatov on 13/10/2021.
//

import Parsing

public struct EnumDecl {
  public let modifiers: [SyntaxNode<DeclModifier>]
  public let enumKeyword: SyntaxNode<Empty>
  public let identifier: SyntaxNode<Identifier>
  public let declarations: SyntaxNode<DeclBlock>
}

extension EnumDecl: SyntaxNodeContainer {
  public var start: SyntaxNode<Empty> { modifiers.first?.empty ?? enumKeyword }
  public var end: SyntaxNode<Empty> { declarations.end }
}

extension EnumDecl: CustomStringConvertible {
  public var description: String {
    "enum \(identifier) {}"
  }
}

let enumParser = Parse {
  Many(declModifierParser)
  Keyword.enum.parser
  identifierParser(requiresLeadingTrivia: true)
  declBlockParser
}
// FIXME: generic parameters
.map(EnumDecl.init)
.map(\.syntaxNode)

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

let structParser = Parse {
  Many(declModifierParser)
  Keyword.struct.parser
  identifierParser(requiresLeadingTrivia: true)
  declBlockParser
}
// FIXME: generic parameters
.map(StructDecl.init)
.map(\.syntaxNode)

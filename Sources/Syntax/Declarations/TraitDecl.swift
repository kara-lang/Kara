//
//  Created by Max Desiatov on 03/09/2021.
//

import Parsing

public struct TraitDecl {
  public let traitKeyword: SyntaxNode<Empty>
  public let identifier: SyntaxNode<Identifier>
  public let declarations: SyntaxNode<DeclBlock>
}

extension TraitDecl: SyntaxNodeContainer {
  public var start: SyntaxNode<Empty> { traitKeyword }

  public var end: SyntaxNode<Empty> { declarations.end }
}

extension TraitDecl: CustomStringConvertible {
  public var description: String {
    "trait \(identifier) {}"
  }
}

let traitParser = Parse {
  Keyword.trait.parser
  identifierParser(requiresLeadingTrivia: true)
  declBlockParser
}
.map(TraitDecl.init)
.map(\.syntaxNode)

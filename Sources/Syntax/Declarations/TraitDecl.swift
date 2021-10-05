//
//  Created by Max Desiatov on 03/09/2021.
//

import Parsing

public struct TraitDecl {
  public let traitKeyword: SyntaxNode<()>
  public let name: SourceRange<TypeIdentifier>
  public let declarations: SyntaxNode<DeclBlock>
}

extension TraitDecl: SyntaxNodeContainer {
  var start: SyntaxNode<()> {
    traitKeyword
  }

  var end: SyntaxNode<()> {
    declarations.end
  }
}

extension TraitDecl: CustomStringConvertible {
  public var description: String {
    "trait \(name) {}"
  }
}

let traitParser = SyntaxNodeParser(Terminal("trait"))
  .take(typeIdentifierParser)
  .take(declBlockParser)
  .map(TraitDecl.init)
  .map(\.syntaxNode)

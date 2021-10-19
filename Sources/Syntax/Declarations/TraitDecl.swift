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
  var start: SyntaxNode<Empty> {
    traitKeyword
  }

  var end: SyntaxNode<Empty> {
    declarations.end
  }
}

extension TraitDecl: CustomStringConvertible {
  public var description: String {
    "trait \(identifier) {}"
  }
}

let traitParser = SyntaxNodeParser(Terminal("trait"))
  .take(identifierParser)
  .take(declBlockParser)
  .map(TraitDecl.init)
  .map(\.syntaxNode)

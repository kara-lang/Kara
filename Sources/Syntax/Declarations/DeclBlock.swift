//
//  Created by Max Desiatov on 05/10/2021.
//

import Parsing

public struct DeclBlock {
  public let openBrace: SyntaxNode<()>
  public let elements: [SyntaxNode<Declaration>]
  public let closeBrace: SyntaxNode<()>
}

extension DeclBlock: SyntaxNodeContainer {
  var start: SyntaxNode<()> {
    openBrace
  }

  var end: SyntaxNode<()> {
    closeBrace
  }
}

let declBlockParser = openBraceParser
  .take(
    Many(
      // FIXME: require separation by a newline
      Lazy { declarationParser }
    )
  )
  .take(closeBraceParser)
  .map(DeclBlock.init)
  .map(\.syntaxNode)

//
//  Created by Max Desiatov on 05/10/2021.
//

import Parsing

public struct DeclBlock {
  public let openBrace: SyntaxNode<Empty>
  public let elements: [SyntaxNode<Declaration>]
  public let closeBrace: SyntaxNode<Empty>
}

extension DeclBlock: SyntaxNodeContainer {
  public var start: SyntaxNode<Empty> { openBrace }
  public var end: SyntaxNode<Empty> { closeBrace }
}

let declBlockParser = Parse {
  openBraceParser
  Many(
    // FIXME: require separation by a newline
    Lazy { declarationParser }
  )
  closeBraceParser
}
.map(DeclBlock.init)
.map(\.syntaxNode)

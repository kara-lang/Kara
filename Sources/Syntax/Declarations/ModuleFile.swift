//
//  Created by Max Desiatov on 04/09/2021.
//

public struct ModuleFile {
  public let declarations: [SyntaxNode<Declaration>]
  public let trailingTrivia: [Trivia]
}

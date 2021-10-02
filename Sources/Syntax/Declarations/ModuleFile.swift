//
//  Created by Max Desiatov on 04/09/2021.
//

import Parsing

public struct ModuleFile {
  public let declarations: [SyntaxNode<Declaration>]
  public let trailingTrivia: [Trivia]
}

let moduleFileParser =
  Many(declarationParser)
    .take(triviaParser)
    .map {
      ModuleFile(declarations: $0, trailingTrivia: $1.map(\.content))
    }.eraseToAnyParser()

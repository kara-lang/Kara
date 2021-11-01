//
//  Created by Max Desiatov on 04/09/2021.
//

import Parsing

public struct ModuleFile<A: Annotation> {
  public var declarations: [SyntaxNode<Declaration<A>>]
  public let trailingTrivia: [Trivia]
}

let moduleFileParser =
  Many(declarationParser)
    .take(triviaParser(requiresLeadingTrivia: false))
    .map {
      ModuleFile(declarations: $0, trailingTrivia: $1.map(\.content))
    }.eraseToAnyParser()

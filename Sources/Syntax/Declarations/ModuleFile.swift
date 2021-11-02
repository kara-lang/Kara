//
//  Created by Max Desiatov on 04/09/2021.
//

import Parsing

public struct ModuleFile<A: Annotation> {
  public var declarations: [SyntaxNode<Declaration<A>>]
  public let trailingTrivia: [Trivia]

  public func addAnnotation<NewAnnotation: Annotation>(
    _ transform: (Declaration<A>) throws -> Declaration<NewAnnotation>
  ) rethrows -> ModuleFile<NewAnnotation> {
    try .init(
      declarations: declarations.map { try $0.map(transform) },
      trailingTrivia: trailingTrivia
    )
  }
}

let moduleFileParser =
  Many(declarationParser)
    .take(triviaParser(requiresLeadingTrivia: false))
    .map {
      ModuleFile(declarations: $0, trailingTrivia: $1.map(\.content))
    }.eraseToAnyParser()

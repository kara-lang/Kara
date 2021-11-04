//
//  Created by Max Desiatov on 05/10/2021.
//

import Parsing

public struct DeclBlock<A: Annotation> {
  public let openBrace: SyntaxNode<Empty>
  public let elements: [SyntaxNode<Declaration<A>>]
  public let closeBrace: SyntaxNode<Empty>

  public func addAnnotation<NewAnnotation: Annotation>(
    _ transform: (Declaration<A>) throws -> Declaration<NewAnnotation>
  ) rethrows -> DeclBlock<NewAnnotation> {
    try .init(
      openBrace: openBrace,
      elements: elements.map { try $0.map(transform) },
      closeBrace: closeBrace
    )
  }
}

extension DeclBlock: SyntaxNodeContainer {
  public var start: SyntaxNode<Empty> { openBrace }
  public var end: SyntaxNode<Empty> { closeBrace }
}

let declBlockParser = openBraceParser
  .take(
    Many(
      // FIXME: require separation by a newline
      Lazy { declarationParser.debug() }
    )
  )
  .take(closeBraceParser.debug())
  .map(DeclBlock.init)
  .map(\.syntaxNode)

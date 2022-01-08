//
//  Created by Max Desiatov on 08/01/2022.
//

import Parsing

public struct GenericConstraints {
  public struct Element: SyntaxNodeContainer {
    public let typeIdentifier: SyntaxNode<Identifier>
    public let isKeyword: SyntaxNode<Empty>
    public let protocolIdentifier: SyntaxNode<Identifier>

    public var start: SyntaxNode<Empty> { typeIdentifier.empty }
    public var end: SyntaxNode<Empty> { protocolIdentifier.empty }
  }

  public let whereKeyword: SyntaxNode<Empty>
  public let elements: UndelimitedSequence<Element>
}

private let constraintElementParser =
  identifierParser()
    .take(Keyword.is.parser)
    .take(identifierParser())
    .map(GenericConstraints.Element.init)
    .map(\.syntaxNode)

let genericConstraintParser =
  Keyword.where.parser
    .take(
      undelimitedSequenceParser(
        separatorParser: commaParser,
        elementParser: constraintElementParser
      )
    ).map(GenericConstraints.init)

//
//  Created by Max Desiatov on 13/10/2021.
//

import Parsing

public struct StructLiteral: SyntaxNodeContainer {
  public struct Element: SyntaxNodeContainer {
    public let property: SyntaxNode<Identifier>
    public let colon: SyntaxNode<()>
    public let value: SyntaxNode<Expr>

    public var start: SyntaxNode<()> {
      property.map { _ in }
    }

    public var end: SyntaxNode<()> {
      value.map { _ in }
    }
  }

  public let type: SyntaxNode<Type>
  public let elements: DelimitedSequence<Element>

  public var start: SyntaxNode<()> {
    type.map { _ in }
  }

  public var end: SyntaxNode<()> {
    elements.end
  }
}

let structLiteralElementParser = identifierParser
  .take(colonParser)
  .take(Lazy { exprParser })
  .map {
    StructLiteral.Element(property: $0, colon: $1, value: $2).syntaxNode
  }

let structLiteralParser = typeParser
  .take(
    delimitedSequenceParser(
      startParser: openSquareBracketParser,
      endParser: closeSquareBracketParser,
      elementParser: structLiteralElementParser
    )
  )
  .map {
    StructLiteral(type: $0, elements: $1).syntaxNode
  }

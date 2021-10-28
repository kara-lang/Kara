//
//  Created by Max Desiatov on 13/10/2021.
//

import Parsing

public struct StructLiteral: SyntaxNodeContainer {
  public struct Element: SyntaxNodeContainer {
    public let property: SyntaxNode<Identifier>
    public let colon: SyntaxNode<Empty>
    public let value: SyntaxNode<Expr>

    public var start: SyntaxNode<Empty> {
      property.empty
    }

    public var end: SyntaxNode<Empty> {
      value.empty
    }
  }

  public let type: SyntaxNode<Expr>
  public let elements: DelimitedSequence<Element>

  public var start: SyntaxNode<Empty> {
    type.empty
  }

  public var end: SyntaxNode<Empty> {
    elements.end
  }
}

let structLiteralElementParser = Parse {
  identifierParser()
  colonParser
  Lazy { exprParser }
}
.map(StructLiteral.Element.init)
.map(\.syntaxNode)

let structLiteralParser = delimitedSequenceParser(
  startParser: openSquareBracketParser,
  endParser: closeSquareBracketParser,
  separatorParser: commaParser,
  elementParser: structLiteralElementParser
)
.map(ExprSyntaxTail.structLiteral)

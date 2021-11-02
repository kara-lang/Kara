//
//  Created by Max Desiatov on 13/10/2021.
//

import Parsing

public struct StructLiteral<A: Annotation>: SyntaxNodeContainer {
  public struct Element: SyntaxNodeContainer {
    public let property: SyntaxNode<Identifier>
    public let colon: SyntaxNode<Empty>
    public let value: SyntaxNode<Expr<A>>

    public var start: SyntaxNode<Empty> {
      property.empty
    }

    public var end: SyntaxNode<Empty> {
      value.empty
    }
  }

  public let type: SyntaxNode<Expr<A>>
  public let elements: DelimitedSequence<Element>

  public var start: SyntaxNode<Empty> {
    type.empty
  }

  public var end: SyntaxNode<Empty> {
    elements.end
  }

  public func addAnnotation<NewAnnotation>(
    type typeTransform: (Expr<A>) throws -> Expr<NewAnnotation>,
    value valueTransform: (Expr<A>) throws -> Expr<NewAnnotation>
  ) rethrows -> StructLiteral<NewAnnotation> {
    try .init(
      type: type.map(typeTransform),
      elements: elements.map {
        try .init(
          property: $0.property,
          colon: $0.colon,
          value: $0.value.map(valueTransform)
        )
      }
    )
  }
}

let structLiteralElementParser = identifierParser()
  .take(colonParser)
  .take(Lazy { exprParser })
  .map {
    StructLiteral.Element(property: $0, colon: $1, value: $2).syntaxNode
  }

let structLiteralParser = delimitedSequenceParser(
  startParser: openSquareBracketParser,
  endParser: closeSquareBracketParser,
  separatorParser: commaParser,
  elementParser: structLiteralElementParser
)
.map(ExprSyntaxTail.structLiteral)

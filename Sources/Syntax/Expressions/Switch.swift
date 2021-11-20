//
//  Created by Max Desiatov on 04/11/2021.
//

import Parsing

public struct Switch<A: Annotation> {
  public struct CaseBlock {
    public typealias Body = [SyntaxNode<ExprBlock<A>.Element>]
    public let casePattern: CasePattern<A>
    public let colon: SyntaxNode<Empty>
    public let body: Body

    public var exprBlock: ExprBlock<A> {
      .init(openBrace: casePattern.caseKeyword, elements: body, closeBrace: body.last?.empty ?? colon)
    }

    public func addAnnotation<NewAnnotation: Annotation>(
      pattern patternTransform: (Expr<A>) throws -> Expr<NewAnnotation>,
      body bodyTransform: (ExprBlock<A>) throws -> ExprBlock<NewAnnotation>
    ) rethrows -> Switch<NewAnnotation>.CaseBlock {
      try .init(
        casePattern: casePattern.addAnnotation(patternTransform),
        colon: colon,
        body: bodyTransform(exprBlock).elements
      )
    }
  }

  public let switchKeyword: SyntaxNode<Empty>
  public let subject: SyntaxNode<Expr<A>>
  public let openBrace: SyntaxNode<Empty>
  public let caseBlocks: [CaseBlock]
  public let closeBrace: SyntaxNode<Empty>

  public func addAnnotation<NewAnnotation: Annotation>(
    subject subjectTransform: (Expr<A>) throws -> Expr<NewAnnotation>,
    caseBlock caseBlockTransform: (CaseBlock) throws -> Switch<NewAnnotation>.CaseBlock
  ) rethrows -> Switch<NewAnnotation> {
    try .init(
      switchKeyword: switchKeyword,
      subject: subject.map(subjectTransform),
      openBrace: openBrace,
      caseBlocks: caseBlocks.map(caseBlockTransform),
      closeBrace: closeBrace
    )
  }
}

extension Switch: SyntaxNodeContainer {
  public var start: SyntaxNode<Empty> { switchKeyword }
  public var end: SyntaxNode<Empty> { closeBrace }
}

private let caseBlockParser =
  casePatternParser
    .take(colonParser)
    .take(exprBlockElementsParser)
    .map(Switch<EmptyAnnotation>.CaseBlock.init)

let switchParser =
  Keyword.switch.parser
    .take(Lazy { exprParser(includeStructLiteral: false) })
    .take(openBraceParser)
    .take(Many(caseBlockParser))
    .take(closeBraceParser)
    .map(Switch.init)
    .map(\.syntaxNode)

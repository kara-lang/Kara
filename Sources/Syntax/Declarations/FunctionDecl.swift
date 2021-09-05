//
//  Created by Max Desiatov on 07/06/2019.
//

import Parsing

public struct FunctionDecl {
  public struct Parameter {
    public let externalName: SourceRange<Identifier>?
    public let internalName: SourceRange<Identifier>
    public let type: SourceRange<Type>
  }

  public let identifier: SourceRange<Identifier>
  public let genericParameters: [TypeVariable]
  public let parameters: SourceRange<[Parameter]>

  // FIXME: Store `SourceRange` for the type
  public let returns: Type
  public let body: SourceRange<Expr>
}

extension FunctionDecl: CustomDebugStringConvertible {
  public var debugDescription: String {
    """
    func \(identifier.element.value)(\(
      parameters.element.map {
        """
        \($0.externalName?.element.value ?? "")\(
          $0.externalName == nil ? "" : " "
        )\($0.internalName.element.value): \($0.type.element)
        """
      }.joined(separator: ", ")
    )) -> \(returns) {
      \(body.element)
    }
    """
  }
}

let functionParameterParser = identifierParser
  .takeSkippingWhitespace(Optional.parser(of: identifierParser))
  .skipWithWhitespace(Terminal(":"))
  .takeSkippingWhitespace(typeParser)
  .map { firstName, secondName, type in
    SourceRange(
      start: firstName.start,
      end: type.end,
      element: FunctionDecl.Parameter(
        externalName: secondName == nil ? nil : firstName,
        internalName: secondName == nil ? firstName : secondName!,
        type: type
      )
    )
  }

let functionDeclParser = Terminal("func")
  .takeSkippingWhitespace(identifierParser)
  .takeSkippingWhitespace(
    delimitedSequenceParser(
      startParser: openParenParser,
      endParser: closeParenParser,
      elementParser: functionParameterParser
    )
  )
  .takeSkippingWhitespace(
    Optional.parser(of: arrowParser)
  )
  .skipWithWhitespace(openBraceParser)
  .takeSkippingWhitespace(exprParser)
  .takeSkippingWhitespace(closeBraceParser)
  .map {
    SourceRange(
      start: $0.start,
      end: $5.end,
      element:
      FunctionDecl(
        identifier: $1,
        // FIXME: fix generic parameters parsing
        genericParameters: [],
        parameters: $2.map { $0.map(\.element) },
        returns: $3?.element ?? .unit,
        body: $4
      )
    )
  }

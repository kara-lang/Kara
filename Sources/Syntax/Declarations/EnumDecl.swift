//
//  Created by Max Desiatov on 13/10/2021.
//

import Parsing

public struct EnumDecl {
  public let modifiers: [SyntaxNode<DeclModifier>]
  public let enumKeyword: SyntaxNode<()>
  public let identifier: SyntaxNode<TypeIdentifier>
  public let genericParameters: [TypeVariable]
  public let declarations: SyntaxNode<DeclBlock>
}

extension EnumDecl: SyntaxNodeContainer {
  var start: SyntaxNode<()> {
    modifiers.first?.map { _ in } ?? enumKeyword
  }

  var end: SyntaxNode<()> {
    declarations.end
  }
}

extension EnumDecl: CustomStringConvertible {
  public var description: String {
    if genericParameters.isEmpty {
      return "enum \(identifier) {}"
    } else {
      return "enum \(identifier)<\(genericParameters.map(\.debugDescription).joined(separator: ", "))> {}"
    }
  }
}

let enumParser =
  Many(declModifierParser)
    .take(SyntaxNodeParser(Terminal("enum")))
    .skip(statefulWhitespace(isRequired: true))
    .take(typeIdentifierParser)
    .take(declBlockParser)
    // FIXME: generic parameters
    .map { EnumDecl(modifiers: $0, enumKeyword: $1, identifier: $2, genericParameters: [], declarations: $3) }
    .map(\.syntaxNode)

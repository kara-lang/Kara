//
//  Created by Max Desiatov on 11/08/2021.
//

import Parsing

public struct StructDecl {
  public let modifiers: [SyntaxNode<DeclModifier>]
  public let structKeyword: SyntaxNode<()>
  public let name: SyntaxNode<TypeIdentifier>
  public let genericParameters: [TypeVariable]
  public let declarations: SyntaxNode<DeclBlock>
}

extension StructDecl: SyntaxNodeContainer {
  var start: SyntaxNode<()> {
    modifiers.first?.map { _ in } ?? structKeyword
  }

  var end: SyntaxNode<()> {
    declarations.end
  }
}

extension StructDecl: CustomStringConvertible {
  public var description: String {
    if genericParameters.isEmpty {
      return "struct \(name) {}"
    } else {
      return "struct \(name)<\(genericParameters.map(\.debugDescription).joined(separator: ", "))> {}"
    }
  }
}

let structParser =
  Many(declModifierParser)
    .take(SyntaxNodeParser(Terminal("struct")))
    .skip(statefulWhitespace(isRequired: true))
    .take(typeIdentifierParser)
    .take(declBlockParser)
    // FIXME: generic parameters
    .map { StructDecl(modifiers: $0, structKeyword: $1, name: $2, genericParameters: [], declarations: $3) }
    .map(\.syntaxNode)

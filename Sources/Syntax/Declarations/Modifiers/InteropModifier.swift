//
//  Created by Max Desiatov on 21/09/2021.
//

import Parsing

public struct InteropModifier: SyntaxNodeContainer {
  public enum Language: String {
    case js = "JS"
    case c = "C"
    case swift = "Swift"
  }

  let interopKeyword: SyntaxNode<Empty>
  let openParen: SyntaxNode<Empty>
  public let language: SyntaxNode<Language>
  let comma: SyntaxNode<Empty>
  public let externalName: SyntaxNode<Substring>
  let closeParen: SyntaxNode<Empty>

  public var start: SyntaxNode<Empty> { interopKeyword }
  public var end: SyntaxNode<Empty> { closeParen }
}

let interopModifierParser = Parse {
  Keyword.interop.parser
  openParenParser
  SyntaxNodeParser(
    identifierSequenceParser
      .compactMap(InteropModifier.Language.init(rawValue:))
      .stateful()
  )
  commaParser
  SyntaxNodeParser(singleQuotedStringParser.stateful()).map(Substring.init)
  closeParenParser
}
.map(InteropModifier.init)
.map(\.syntaxNode)
.map { $0.map(DeclModifier.interop) }

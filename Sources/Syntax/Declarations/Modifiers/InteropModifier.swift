//
//  Created by Max Desiatov on 21/09/2021.
//

struct InteropModifier {
  enum Language: String {
    case js = "JS"
    case c = "C"
    case swift = "Swift"
  }

  let interopKeyword: SyntaxNode<()>
  let openParen: SyntaxNode<()>
  let language: SyntaxNode<Language>
  let comma: SyntaxNode<()>
  let externalName: SyntaxNode<UTF8SubSequence>
  let closeParen: SyntaxNode<()>
}

let interopModifierParser = SyntaxNodeParser(Terminal("interop"))
  .take(SyntaxNodeParser(openBraceParser))
  .take(SyntaxNodeParser(identifierSequenceParser.stateful()))
  .take(SyntaxNodeParser(commaParser))
  .take(SyntaxNodeParser(singleQuotedStringParser.stateful()))
  .take(SyntaxNodeParser(closeBraceParser))
  .compactMap { interopKeyword, openParen, rawLanguage, comma, externalName, closeParen -> InteropModifier? in
    guard let language = InteropModifier.Language(rawValue: rawLanguage.content.content) else {
      return nil
    }

    return InteropModifier(
      interopKeyword: interopKeyword,
      openParen: openParen,
      language: rawLanguage.map { _ in language },
      comma: comma,
      externalName: externalName,
      closeParen: closeParen
    )
  }

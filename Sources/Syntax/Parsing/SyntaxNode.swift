//
//  Created by Max Desiatov on 10/09/2021.
//

struct SyntaxNode<Content> {
  let leadingTrivia: [Trivia]
  let content: SourceRange<Content>

  func map<NewContent>(_ transform: (Content) -> NewContent) -> SyntaxNode<NewContent> {
    .init(leadingTrivia: leadingTrivia, content: content.map(transform))
  }
}

//
//  Created by Max Desiatov on 04/11/2021.
//

struct CasePattern<A: Annotation> {
  public let caseKeyword: SyntaxNode<Empty>
  public let bindingKeyword: SyntaxNode<Empty>?
}

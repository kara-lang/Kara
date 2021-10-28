//
//  Created by Max Desiatov on 27/10/2021.
//

import Parsing

public struct LeadingDot: SyntaxNodeContainer {
  public let dot: SyntaxNode<Empty>
  public let member: SyntaxNode<Identifier>

  public var start: SyntaxNode<Empty> { dot }
  public var end: SyntaxNode<Empty> { member.empty }
}

let leadingDotParser = Parse {
  dotParser
  identifierParser()
}
.map(LeadingDot.init)
.map(\.syntaxNode)

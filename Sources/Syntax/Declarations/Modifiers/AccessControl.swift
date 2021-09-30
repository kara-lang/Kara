//
//  Created by Max Desiatov on 30/09/2021.
//

public enum AccessControl {
  case `public`
  case `private`
}

let accessControlParser =
  SyntaxNodeParser(
    Terminal("public").map { $0.map { _ in DeclModifier.access(.public) } }
      .orElse(
        Terminal("private").map { $0.map { _ in DeclModifier.access(.private) } }
      )
  )

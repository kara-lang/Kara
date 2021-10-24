//
//  Created by Max Desiatov on 30/09/2021.
//

public enum AccessControl {
  case `public`
  case `private`
}

let accessControlParser =
  Keyword.public.parser.map { $0.map { _ in DeclModifier.access(.public) } }
    .orElse(
      Keyword.private.parser.map { $0.map { _ in DeclModifier.access(.private) } }
    )

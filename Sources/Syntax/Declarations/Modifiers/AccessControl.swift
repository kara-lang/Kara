//
//  Created by Max Desiatov on 30/09/2021.
//

import Parsing

public enum AccessControl {
  case `public`
  case `private`
}

let accessControlParser = OneOf {
  Keyword.public.parser.map { _ in DeclModifier.access(.public) }
  Keyword.private.parser.map { _ in DeclModifier.access(.private) }
}

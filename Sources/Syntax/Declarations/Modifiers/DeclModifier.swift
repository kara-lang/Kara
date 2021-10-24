//
//  Created by Max Desiatov on 21/09/2021.
//

public enum DeclModifier {
  case access(AccessControl)
  case interop(InteropModifier)
  case `static`
}

let declModifierParser = interopModifierParser
  .orElse(accessControlParser)
  .orElse(Keyword.static.parser.map { $0.map { _ in .static }})

//
//  Created by Max Desiatov on 21/09/2021.
//

public enum DeclModifier {
  case access(AccessControl)
  case interop(InteropModifier)
}

let declModifierParser = interopModifierParser
  .orElse(accessControlParser)

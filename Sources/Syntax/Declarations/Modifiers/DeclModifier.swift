//
//  Created by Max Desiatov on 21/09/2021.
//

enum AccessControl {
  case `public`
  case `private`
}

enum DeclModifier {
  case access(AccessControl)
  case interop(InteropModifier)
}

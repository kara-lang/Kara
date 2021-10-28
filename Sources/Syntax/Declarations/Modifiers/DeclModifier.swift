//
//  Created by Max Desiatov on 21/09/2021.
//

import Parsing

public enum DeclModifier {
  case access(AccessControl)
  case interop(InteropModifier)
  case `static`
}

let declModifierParser = OneOf {
  interopModifierParser
  accessControlParser
  Keyword.static.parser.map { _ in DeclModifier.static }
}

public protocol ModifiersContainer {
  var modifiers: [SyntaxNode<DeclModifier>] { get }
}

public extension ModifiersContainer {
  var isStatic: Bool {
    modifiers.map(\.content.content).contains {
      switch $0 {
      case .static:
        return true
      default:
        return false
      }
    }
  }
}

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

//
//  Created by Max Desiatov on 16/10/2021.
//

import Syntax

/// A type that represents an evaluated in-memory expression that doesn't have a corresponding
/// syntax node in a source file. Compared to `enum Expr` in `Syntax` module,
/// no syntactic information is stored here such as source location or trivia.
enum NormalForm: Hashable {
  case identifier(Identifier)
  case literal(Literal)
  case tuple([NormalForm])
  case structLiteral(Identifier, [Identifier: NormalForm])
  case typeConstructor(Identifier, [NormalForm])
  indirect case memberAccess(NormalForm, MemberAccess.Member)
  indirect case closure(parameters: [Identifier], body: NormalForm)
  indirect case ifThenElse(condition: Identifier, then: NormalForm, else: NormalForm)
  indirect case arrow([NormalForm], NormalForm)

  var type: Type? {
    switch self {
    case let .tuple(elements):
      return elements.types.map(Type.tuple)

    case let .typeConstructor(id, args):
      return args.types.map { .constructor(id, $0) }

    case let .arrow(head, tail):
      guard let headTypes = head.types, let tailType = tail.type else {
        return nil
      }

      return .arrow(headTypes, tailType)

    case .closure, .literal, .ifThenElse, .structLiteral, .identifier, .memberAccess:
      return nil
    }
  }
}

extension Array where Element == NormalForm {
  var types: [Type]? {
    var elementTypes = [Type]()
    for element in self {
      guard let type = element.type else {
        return nil
      }
      elementTypes.append(type)
    }

    return elementTypes
  }
}

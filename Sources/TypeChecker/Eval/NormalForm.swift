//
//  Created by Max Desiatov on 16/10/2021.
//

import Syntax

enum NormalForm: Hashable {
  // FIXME: use a different closure type separate from the `Syntax` type
  case closure(Closure)
  case literal(Literal)
  indirect case ifThenElse(condition: Identifier, then: NormalForm, else: NormalForm)
  case tuple([NormalForm])
  case structLiteral(Identifier, [Identifier: NormalForm])
  case typeConstructor(Identifier, [NormalForm])
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

    case .closure, .literal, .ifThenElse, .structLiteral:
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

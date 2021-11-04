//
//  Created by Max Desiatov on 16/10/2021.
//

import Syntax

/** Represents an evaluated in-memory expression that doesn't have a corresponding
 syntax node in a source file. Compared to `enum Expr` in `Syntax` module, no syntactic information is stored
 here such as source location or trivia. Note that sometimes evaluation from `Expr` to `NormalForm` can be only
 partial. For example, unapplied closures can't be fully evaluated without their arguments. Because of that we
 need to be able to represent unsubstituted identifiers within closure bodies with `NormalForm`. That's why there
 are more cases in this `enum` than one would initially expect from complete evaluation of simple expressions.
 */
enum NormalForm: Hashable {
  case identifier(Identifier)
  case literal(Literal)
  case tuple([NormalForm])
  case structLiteral(Identifier, [Identifier: NormalForm])
  case typeConstructor(Identifier, [NormalForm])
  indirect case memberAccess(NormalForm, Member)
  indirect case closure(parameters: [Identifier], body: NormalForm)
  indirect case ifThenElse(condition: Identifier, then: NormalForm, else: NormalForm)
  indirect case arrow([NormalForm], NormalForm)

  /// Returns a `Type` representation of `self` if it is inferrred to be a type expression. Returns `nil` otherwise.
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

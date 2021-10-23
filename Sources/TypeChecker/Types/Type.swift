//
//  Created by Max Desiatov on 27/04/2019.
//

import Syntax

public enum Type {
  /** A type constructor is an abstraction on which generics system is built.
   It is a "type function", which takes other types as arguments and returns
   a new type. `Type.constructor("Int", [])` represents an `Int` type, while
   `Type.constructor("Dictionary", ["String", "Int"])` represents a
   `[String: Int]` type (`Dictionary<String, Int>` when desugared).

   Examples:

   * `Int` and `String` are nullary type constructors, they
   don't take any type arguments and already represent a ready to use type.

   * `Array` is a unary type constructor, which takes a single type argument:
   a type of its element. `Array<Int>` is a type constructor applied to the
   `Int` argument and produces a type for an array of integers.

   * `Dictionary` is a binary type constructor with two type arguments
   for the key type and value type respectively. `Dictionary<String, Int>` is
   a binary type constructor applied to produce a dictionary from `String` keys
   to `Int` values.

   * `->` is a binary type constructor with two type arguments for the argument
   and for the return value of a function. It is written as a binary operator
   to produce a type like `ArgsType -> ReturnType`. Note that we use a separate
   enum `case arrow(Type, Type)` for this due to a special treatment of function
   types in the type checker.

   Since type constructors are expected to be applied to a correct number of
   type arguments, it's useful to introduce a notion of
   ["kinds"](https://en.wikipedia.org/wiki/Kind_(type_theory)). At compile time
   all values have types that help us verify correctness of expressions, types
   have kinds that allow us to verify type constructor applications.

   The only available primitive kind in Kara is `Type`.
   */
  case constructor(Identifier, [Type])

  /** A free type variable that can be used as a temporary placeholder type
   during type inference, or as a type variable in a generic declaration as a
   part of a `Scheme` value.
   */
  case variable(TypeVariable)

  /** Binary type operator `->` representing function types.
   */
  indirect case arrow([Type], Type)

  /** Tuple types, where each element of an associated array is a corresponding
   type of the tuple's element.

   ```
   (Int, String, Bool)
   ```

   is represented in Kara as

   ```
   Type.tuple([.int, .string, .bool])
   ```
   */
  case tuple([Type])

  /** The kind of all other types representable in Kara.
   */
  public static let type = Type.constructor("Type", [])

  public static let bool = Type.constructor("Bool", [])
  public static let string = Type.constructor("String", [])
  public static let double = Type.constructor("Double", [])
  public static let int32 = Type.constructor("Int32", [])
  public static let int64 = Type.constructor("Int64", [])

  public static let unit = Type.tuple([])
}

extension Type: Equatable {
  public static func == (lhs: Type, rhs: Type) -> Bool {
    switch (lhs, rhs) {
    case let (.constructor(id1, t1), .constructor(id2, t2)):
      return id1 == id2 && t1 == t2
    case (.constructor, _):
      return false
    case let (.variable(v1), .variable(v2)):
      return v1 == v2
    case (.variable, _):
      return false
    case let (.arrow(i1, o1), .arrow(i2, o2)):
      return i1 == i2 && o1 == o2
    case (.arrow, _):
      return false
    case let (.tuple(t1), .tuple(t2)):
      return t1 == t2
    case (.tuple, _):
      return false
    }
  }
}

extension Type: Hashable {
  public func hash(into hasher: inout Hasher) {
    switch self {
    case let .constructor(id, args):
      hasher.combine(id)
      hasher.combine(args)
    case let .variable(v):
      hasher.combine(v)
    case let .arrow(head, tail):
      hasher.combine(head)
      hasher.combine(tail)
    case let .tuple(elements):
      hasher.combine(elements)
    }
  }
}

extension Type: CustomStringConvertible {
  public var description: String {
    switch self {
    case let .constructor(id, args) where !args.isEmpty:
      return "\(id.value)<\(args.map(\.description).joined(separator: ", "))>"
    case let .constructor(id, _):
      return id.value
    case let .variable(v):
      return v.value
    case let .arrow(args, result):
      guard args.count > 0 else { return "(() -> \(result))" }

      guard args.count > 1 else { return "(\(args[0]) -> \(result))" }

      return "((\(args.map(\.description).joined(separator: ", "))) -> \(result))"
    case let .tuple(elements):
      return """
      (\(elements.map(\.description).joined(separator: ", ")))
      """
    }
  }
}

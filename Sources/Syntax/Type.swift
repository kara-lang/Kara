//
//  Created by Max Desiatov on 27/04/2019.
//

public struct TypeVariable: Hashable {
  let value: String
}

extension TypeVariable: ExpressibleByStringLiteral {
  public init(stringLiteral value: String) {
    self.value = value
  }
}

extension TypeVariable: CustomDebugStringConvertible {
  public var debugDescription: String {
    value
  }
}

extension TypeVariable: ExpressibleByStringInterpolation {
  public init(stringInterpolation: DefaultStringInterpolation) {
    value = stringInterpolation.description
  }
}

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
   have kinds that allow us to verify type constructor applications. Note that
   this is different from metatypes in Swift. Metatypes are still types,
   and metatype values can be stored as constants/variables and operated on at
   run time. Kinds are completely separate from this, and are a purely
   compile-time concept that helps us to reason about generic types.

   All nullary type constructors have a kind `*`, you can think of `*` as a
   "placeholder" for a type. If we use `::` to represent "has a kind"
   declarations, we could declare that `Int :: *` or `String :: *`. Unary type
   constructors have a kind `<*> ~> *`, where `~>` is a binary operator for a
   "type function", and so `Array :: <*> ~> *`, while `Array<Int> :: *`. A
   binary type constructor has a kind `<*, *> ~> *`, therefore
   `Dictionary :: <*, *> ~> *` and `Dictionary<String, Int> :: *`.

   In Kara we adopt a notation for kinds similar to the one
   used in the widely available content on the type theory, but slightly
   modified for Kara. Specifically, type constructors in Swift don't use
   [currying](https://en.wikipedia.org/wiki/Currying), and Kara uses `~>`
   for type functions on the level of kinds, compared to `->` for value
   functions used on the level of types. Compare this to the type theory papers,
   which commonly use `->` on both levels. We find the common approach confusing
   in the context of Kara's type system.
   */
  case constructor(TypeIdentifier, [Type])

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
  case namedTuple([(Identifier?, Type)])

  public static func tuple(_ types: [Type]) -> Type {
    .namedTuple(types.enumerated().map {
      (nil, $0.1)
    })
  }

  public static let bool = Type.constructor("Bool", [])
  public static let string = Type.constructor("String", [])
  public static let double = Type.constructor("Double", [])
  public static let int = Type.constructor("Int", [])
}

infix operator -->

/// A shorthand version of `Type.arrow`
public func --> (arguments: [Type], returned: Type) -> Type {
  Type.arrow(arguments, returned)
}

/// A shorthand version of `Type.arrow` for single argument functions
public func --> (argument: Type, returned: Type) -> Type {
  Type.arrow([argument], returned)
}

extension Type: Equatable {
  public static func == (lhs: Type, rhs: Type) -> Bool {
    switch (lhs, rhs) {
    case let (.constructor(id1, t1), .constructor(id2, t2)):
      return id1 == id2 && t1 == t2
    case let (.variable(v1), .variable(v2)):
      return v1 == v2
    case let (.arrow(i1, o1), .arrow(i2, o2)):
      return i1 == i2 && o1 == o2
    default:
      return false
    }
  }
}

extension Type: CustomDebugStringConvertible {
  public var debugDescription: String {
    switch self {
    case let .constructor(id, args) where !args.isEmpty:
      return "\(id.value)<\(args.map(\.debugDescription).joined(separator: ", "))>"
    case let .constructor(id, _):
      return id.value
    case let .variable(v):
      return v.value
    case let .arrow(args, result):
      return "(\(args.map(\.debugDescription).joined(separator: ", "))) -> \(result)"
    case let .namedTuple(elements):
      return """
      (\(elements.map { identifier, type -> String in
        if let identifier = identifier {
          return "\(identifier): \(type.debugDescription)"
        } else {
          return type.debugDescription
        }
      }.joined(separator: ", ")))
      """
    }
  }
}

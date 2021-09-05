//
//  Created by Max Desiatov on 27/04/2019.
//

import Parsing

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
  case tuple([Type])

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
      guard args.count > 0 else { return "(() -> \(result))" }

      guard args.count > 1 else { return "(\(args[0]) -> \(result))" }

      return "((\(args.map(\.debugDescription).joined(separator: ", "))) -> \(result))"
    case let .tuple(elements):
      return """
      (\(elements.map(\.debugDescription).joined(separator: ", ")))
      """
    }
  }
}

private let typeConstructorParser = identifierSequenceParser
  .map(TypeIdentifier.init(value:))
  .stateful()

private let arrowParser = Terminal("->")
  .ignoreOutput()
  .skip(StatefulWhitespace())
  .take(Lazy { typeParser })

let tupleTypeParser = delimitedSequenceParser(
  startParser: openParenParser,
  endParser: closeParenParser,
  elementParser: Lazy { typeParser }
)

private let genericsParser = delimitedSequenceParser(
  startParser: openAngleBracketParser,
  endParser: closeAngleBracketParser,
  elementParser: Lazy { typeParser },
  // There's always at least one generic argument to a type constructor, otherwise it shouldn't be written as generic.
  atLeast: 1
)
// Fully consume the type tail, don't stop with generic arguments.
.skip(StatefulWhitespace())
.take(
  Optional.parser(
    of: arrowParser
  )
)
.map { genericArguments, arrowOutput in
  // Transform inner source range element.
  SourceRange(
    start: genericArguments.start,
    end: arrowOutput?.end ?? genericArguments.end,
    element: TypeSyntaxTail.generic(
      // Pluck only `element` value from every argument.
      arguments: genericArguments.element.map(\.element),
      arrowOutput: arrowOutput?.element
    )
  )
}

// .eraseToAnyParser()

private enum TypeSyntaxHead {
  case tuple([Type])
  case constructor(head: TypeIdentifier)
}

private enum TypeSyntaxTail {
  case arrow(output: Type)
  case generic(arguments: [Type], arrowOutput: Type?)
}

let typeParser: AnyParser<ParsingState, SourceRange<Type>> =
  tupleTypeParser
    .map { $0.map { TypeSyntaxHead.tuple($0.map(\.element)) } }
    .orElse(
      typeConstructorParser
        .map { $0.map(TypeSyntaxHead.constructor) }
    )
    .takeSkippingWhitespace(
      Optional.parser(
        of: arrowParser
          .map { $0.map(TypeSyntaxTail.arrow) }
          .orElse(
            genericsParser
          )
      )
    )
    .compactMap {
      let headType: SourceRange<Type>
      switch $0.element {
      case let .tuple(elements):
        headType = $0.map { _ in Type.tuple(elements) }

      case let .constructor(typeIdentifier):
        headType = $0.map { _ in Type.constructor(typeIdentifier, []) }
      }

      guard let tail = $1 else { return headType }

      switch tail.element {
      case let .arrow(output):
        return SourceRange(
          start: $0.start,
          end: tail.end,
          element: Type.arrow([headType.element], output)
        )

      case let .generic(arguments, arrowOutput):
        // FIXME: better error message here?
        guard case let .constructor(head, _) = headType.element else { return nil }

        if let arrowOutput = arrowOutput {
          return SourceRange(
            start: headType.start,
            end: tail.end,
            element: Type.arrow([.constructor(head, arguments)], arrowOutput)
          )
        } else {
          return SourceRange(
            start: headType.start,
            end: tail.end,
            element: Type.constructor(head, arguments)
          )
        }
      }
    }
    .eraseToAnyParser()

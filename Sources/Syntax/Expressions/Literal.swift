//
//  Created by Max Desiatov on 25/05/2019.
//

import Parsing

public enum Literal: Hashable {
  case int32(Int32)
  case int64(Int64)
  case double(Double)
  case bool(Bool)
  case string(String)

  public var defaultType: Type {
    switch self {
    case .int32:
      return .int32
    case .int64:
      return .int64
    case .double:
      return .double
    case .bool:
      return .bool
    case .string:
      return .string
    }
  }
}

extension Literal: ExpressibleByStringLiteral {
  public init(stringLiteral value: String) {
    self = .string(value)
  }
}

extension Literal: ExpressibleByIntegerLiteral {
  public init(integerLiteral value: IntegerLiteralType) {
    self = value > Int32.max ? .int64(Int64(value)) : .int32(Int32(truncatingIfNeeded: value))
  }
}

extension Literal: ExpressibleByFloatLiteral {
  public init(floatLiteral value: Double) {
    self = .double(value)
  }
}

extension Literal: ExpressibleByBooleanLiteral {
  public init(booleanLiteral value: BooleanLiteralType) {
    self = .bool(value)
  }
}

extension Literal: CustomStringConvertible {
  public var description: String {
    switch self {
    case let .bool(b): return b.description
    case let .double(f): return f.description
    case let .int32(i32): return i32.description
    case let .int64(i64): return i64.description
    case let .string(s): return #""\#(s)""#
    }
  }
}

let intLiteralParser = Int64.parser(of: UTF8SubSequence.self)
  // resolve ambiguity with floats
  .lookahead(amount: 2) { (lookaheadPrefix: UTF8SubSequence) -> Bool in
    // end of input means that integer is valid
    guard
      lookaheadPrefix.count > 0,
      let firstPrefixElement = lookaheadPrefix.first,
      firstPrefixElement == UInt8(ascii: ".")
    else { return true }

    // if `.` is located at the end of input, this looks like an invalid token.
    guard lookaheadPrefix.count > 1,
          let lastPrefixElement = lookaheadPrefix.last else { return false }

    return !(UInt8(ascii: "0")...UInt8(ascii: "9")).contains(lastPrefixElement)
  }
  .map {
    $0 > Int32.max ? Literal.int64($0) : Literal.int32(Int32(truncatingIfNeeded: $0))
  }

let floatLiteralParser = Double.parser(of: UTF8SubSequence.self)
  .map(Literal.double)

let singleQuotedStringParser = UTF8Terminal("\"".utf8)
  .take(Prefix { $0 != UInt8(ascii: "\"") })
  .skip(StartsWith("\"".utf8))

let stringLiteralParser = singleQuotedStringParser
  .compactMap(String.init)
  .map(Literal.string)

let boolLiteralParser = UTF8Terminal("true".utf8)
  .map { _ in true }
  .orElse(
    UTF8Terminal("false".utf8)
      .map { _ in false }
  )
  .map(Literal.bool)

let literalParser =
  intLiteralParser
    .orElse(floatLiteralParser)
    .orElse(stringLiteralParser)
    .orElse(boolLiteralParser)

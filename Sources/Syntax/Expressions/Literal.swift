//
//  Created by Max Desiatov on 25/05/2019.
//

import Parsing

public enum Literal: Equatable {
  case integer(Int)
  case float(Double)
  case bool(Bool)
  case string(String)

  public var defaultType: Type {
    switch self {
    case .integer:
      return .int
    case .float:
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
    self = .integer(value)
  }
}

extension Literal: ExpressibleByFloatLiteral {
  public init(floatLiteral value: FloatLiteralType) {
    self = .float(value)
  }
}

extension Literal: ExpressibleByBooleanLiteral {
  public init(booleanLiteral value: BooleanLiteralType) {
    self = .bool(value)
  }
}

extension Literal: CustomDebugStringConvertible {
  public var debugDescription: String {
    switch self {
    case let .bool(b): return b.description
    case let .float(f): return f.description
    case let .integer(i): return i.description
    case let .string(s): return #""\#(s)""#
    }
  }
}

let intLiteralParser = Int.parser(of: UTF8SubSequence.self)
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
  .map(Literal.integer)

let floatLiteralParser = Double.parser(of: UTF8SubSequence.self)
  .map(Literal.float)

let stringLiteralParser = UTF8Terminal("\"".utf8)
  .take(Prefix { $0 != UInt8(ascii: "\"") })
  .skip(StartsWith("\"".utf8))
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

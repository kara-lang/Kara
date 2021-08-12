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

let intLiteralParser = Int.parser(of: UTF8Subsequence.self)
  .skip(End().orElse(StartsWith(" ".utf8)).orElse(Newline()))
  .map(Literal.integer)

let floatLiteralParser = Double.parser(of: UTF8Subsequence.self)
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

//
//  Created by Max Desiatov on 18/08/2021.
//

import CustomDump
@testable import Syntax
@testable import TypeChecker
import XCTest

extension String {
  func inferParsedExpr(
    environment: Environment = [:],
    members: Members = [:]
  ) throws -> Type {
    var state = ParsingState(source: self)
    guard let expr = exprParser.parse(&state) else {
      throw ParsingError.unknown(startIndex..<endIndex)
    }

    return try expr.content.content.infer(environment: environment, members: members)
  }
}

final class SyntaxInferenceTests: XCTestCase {
  func testApplication() throws {
    let e: Environment = [
      "increment": .init(.int32 --> .int32),
      "stringify": .init(.int32 --> .string),
    ]

    try XCTAssertNoDifference("increment(0)".inferParsedExpr(environment: e), .int32)
    try XCTAssertNoDifference("stringify(0)".inferParsedExpr(environment: e), .string)
    XCTAssertThrowsError(try "increment(false)".inferParsedExpr())
    XCTAssertThrowsError(try "increment(false)".inferParsedExpr(environment: e))
  }

  func testClosure() throws {
    let e: Environment = [
      "increment": .init(.int32 --> .int32),
      "stringify": .init(.int32 --> .string),
      "decode": .init(.string --> .int32),
    ]

    XCTAssertNoDifference(
      try exprParser.parse(
        """
        { x in decode(stringify(increment(x))) }
        """
      ).output?.content.content.infer(environment: e), .int32 --> .int32
    )

    assertError(
      try exprParser.parse(
        """
        { x in stringify(decode(increment(x))) }
        """
      ).output?.content.content.infer(environment: e),
      TypeError.unificationFailure(.string, .int32)
    )

    assertError(
      try exprParser.parse(
        """
        { x in stringify(decode(increment(x))) }
        """
      ).output?.content.content.infer(),
      TypeError.unbound("stringify")
    )
  }

  func testClosureWithMultipleArguments() throws {
    let e: Environment = [
      "sum": .init([.int32, .int32] --> .int32),
      "stringify": .init([.int32, .int32] --> .string),
      "decode": .init([.string, .string] --> .int32),
    ]

    XCTAssertNoDifference(
      try exprParser.parse(
        """
        { x, y in
          decode(
            stringify(
              sum(x,y),
              sum(x,y)
            ),
            stringify(
              sum(x,y),
              sum(x,y)
            )
          )
        }
        """
      ).output?.content.content.infer(environment: e), [.int32, .int32] --> .int32
    )
  }

  func testClosureWithMultipleArgumentsDifferentTypes() throws {
    let e: Environment = [
      "concatenate": .init([.int32, .string] --> .string),
      "sum": .init([.int32, .int32] --> .int32),
      "decode": .init([.string, .int32] --> .int32),
    ]

    XCTAssertNoDifference(
      try exprParser.parse(
        """
        { str, int in
          decode(
            concatenate(int, str),
            sum(int, int)
          )
        }
        """
      ).output?.content.content.infer(environment: e),
      [.string, .int32] --> .int32
    )
  }

  func testMember() throws {
    let m: Members = [
      "String": [
        "appending": .init(.string --> .string),
        "count": .init(.int32),
      ],
    ]

    XCTAssertNoDifference(
      try exprParser.parse(#""Hello, ".appending("World!")"#).output?.content.content.infer(members: m),
      .string
    )
    XCTAssertNoDifference(
      try exprParser.parse(#""Test".count"#).output?.content.content.infer(members: m),
      .int32
    )
    assertError(
      try exprParser.parse(#""Test".description"#).output?.content.content.infer(members: m),
      TypeError.unknownMember("String", "description")
    )
  }

  func testMemberOfMember() throws {
    let m: Members = [
      "String": [
        "count": .init(.int32),
      ],
      "Int32": [
        "magnitude": .init(.int32),
      ],
    ]

    XCTAssertNoDifference(
      try exprParser.parse(#""Test".count.magnitude"#).output?.content.content.infer(members: m),
      .int32
    )
    assertError(
      try exprParser.parse(#""Test".magnitude.count"#).output?.content.content.infer(members: m),
      TypeError.unknownMember("String", "magnitude")
    )
  }

  func testIfThenElse() throws {
    let m: Members = [
      "Int32": [
        "isInteger": .init(.bool),
        "isIntegerFunc": .init([] --> .bool),
        "toDouble": .init([] --> .double),
      ],
    ]

    let e: Environment = [
      "foo": .init(.bool),
      "bar": .init(.double),
      "baz": .init(.double),
      "fizz": .init(.int32),
    ]

    XCTAssertNoDifference(
      try exprParser.parse(#"if true { "true" } else { "false" } "#).output?.content.content.infer(members: m),
      .string
    )
    XCTAssertNoDifference(
      try exprParser.parse(#"if foo { bar } else { baz }  "#).output?.content.content.infer(environment: e, members: m),
      .double
    )
    XCTAssertNoDifference(
      try exprParser.parse(
        #"""
        if 42.isInteger {
          "is integer"
        } else {
          "is not integer"
        }
        """#
      ).output?.content.content.infer(environment: e, members: m),
      .string
    )
    XCTAssertNoDifference(
      try exprParser.parse(
        #"""
        if 42.isIntegerFunc() {
          "is integer"
        } else {
          "is not integer"
        }
        """#
      ).output?.content.content.infer(environment: e, members: m),
      .string
    )
    assertError(
      try exprParser.parse(
        #"""
        if 42.toDouble() {
          "is integer"
        } else {
          "is not integer"
        }
        """#
      ).output?.content.content.infer(members: m),
      TypeError.unificationFailure(.double, .bool)
    )
    assertError(
      try exprParser.parse(
        #"""
        if 42 {
          "is integer"
        } else {
          "is not integer"
        }
        """#
      ).output?.content.content.infer(members: m),
      TypeError.unificationFailure(.int32, .bool)
    )
  }
}

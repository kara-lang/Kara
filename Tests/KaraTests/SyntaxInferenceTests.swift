//
//  Created by Max Desiatov on 18/08/2021.
//

@testable import Syntax
@testable import Types
import XCTest

final class SyntaxInferenceTests: XCTestCase {
  func testApplication() throws {
    let e: Environment = [
      "increment": [.init(.int --> .int)],
      "stringify": [.init(.int --> .string)],
    ]

    try XCTAssertEqual("increment(0)".inferParsedExpr(environment: e), .int)
    try XCTAssertEqual("stringify(0)".inferParsedExpr(environment: e), .string)
    XCTAssertThrowsError(try "increment(false)".inferParsedExpr())
    XCTAssertThrowsError(try "increment(false)".inferParsedExpr(environment: e))
  }

  func testClosure() throws {
    let e: Environment = [
      "increment": [.init(.int --> .int)],
      "stringify": [.init(.int --> .string)],
      "decode": [.init(.string --> .int)],
    ]

    XCTAssertEqual(
      try exprParser.parse(
        """
        { x in decode(stringify(increment(x))) }
        """
      ).output?.element.infer(environment: e), .int --> .int
    )

    assertError(
      try exprParser.parse(
        """
        { x in stringify(decode(increment(x))) }
        """
      ).output?.element.infer(environment: e),
      TypeError.unificationFailure(.string, .int)
    )

    assertError(
      try exprParser.parse(
        """
        { x in stringify(decode(increment(x))) }
        """
      ).output?.element.infer(),
      TypeError.unbound("stringify")
    )
  }

  func testClosureWithMultipleArguments() throws {
    let e: Environment = [
      "sum": [.init([.int, .int] --> .int)],
      "stringify": [.init([.int, .int] --> .string)],
      "decode": [.init([.string, .string] --> .int)],
    ]

    XCTAssertEqual(
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
      ).output?.element.infer(environment: e), [.int, .int] --> .int
    )
  }

  func testClosureWithMultipleArgumentsDifferentTypes() throws {
    let e: Environment = [
      "concatenate": [.init([.int, .string] --> .string)],
      "sum": [.init([.int, .int] --> .int)],
      "decode": [.init([.string, .int] --> .int)],
    ]

    XCTAssertEqual(
      try exprParser.parse(
        """
        { str, int in
          decode(
            concatenate(int, str),
            sum(int, int)
          )
        }
        """
      ).output?.element.infer(environment: e),
      [.string, .int] --> .int
    )
  }

  func testMember() throws {
    let m: Members = [
      "String": [
        "appending": [.init(.string --> .string)],
        "count": [.init(.int)],
      ],
    ]

    XCTAssertEqual(
      try exprParser.parse(#""Hello, ".appending("World!")"#).output?.element.infer(members: m),
      .string
    )
    XCTAssertEqual(
      try exprParser.parse(#""Test".count"#).output?.element.infer(members: m),
      .int
    )
    assertError(
      try exprParser.parse(#""Test".description"#).output?.element.infer(members: m),
      TypeError.unknownMember("String", "description")
    )
  }

  func testMemberOfMember() throws {
    let m: Members = [
      "String": [
        "count": [.init(.int)],
      ],
      "Int": [
        "magnitude": [.init(.int)],
      ],
    ]

    XCTAssertEqual(
      try exprParser.parse(#""Test".count.magnitude"#).output?.element.infer(members: m),
      .int
    )
    assertError(
      try exprParser.parse(#""Test".magnitude.count"#).output?.element.infer(members: m),
      TypeError.unknownMember("String", "magnitude")
    )
  }

  func testIfThenElse() throws {
    let m: Members = [
      "Int": [
        "isInteger": [.init(.bool)],
        "isIntegerFunc": [.init([] --> .bool)],
        "toDouble": [.init([] --> .double)],
      ],
    ]

    let e: Environment = [
      "foo": [.init(.bool)],
      "bar": [.init(.double)],
      "baz": [.init(.double)],
      "fizz": [.init(.int)],
    ]

    XCTAssertEqual(
      try exprParser.parse(#"if true { "true" } else { "false" } "#).output?.element.infer(members: m),
      .string
    )
    XCTAssertEqual(
      try exprParser.parse(#"if foo { bar } else { baz }  "#).output?.element.infer(environment: e, members: m),
      .double
    )
    XCTAssertEqual(
      try exprParser.parse(
        #"""
        if 42.isInteger {
          "is integer"
        } else {
          "is not integer"
        }
        """#
      ).output?.element.infer(environment: e, members: m),
      .string
    )
    XCTAssertEqual(
      try exprParser.parse(
        #"""
        if 42.isIntegerFunc() {
          "is integer"
        } else {
          "is not integer"
        }
        """#
      ).output?.element.infer(environment: e, members: m),
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
      ).output?.element.infer(members: m),
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
      ).output?.element.infer(members: m),
      TypeError.unificationFailure(.int, .bool)
    )
  }
}

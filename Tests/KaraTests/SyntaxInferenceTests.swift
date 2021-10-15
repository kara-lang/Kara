//
//  Created by Max Desiatov on 18/08/2021.
//

import CustomDump
@testable import Syntax
@testable import TypeChecker
import XCTest

extension String {
  func inferParsedExpr(
    environment: DeclEnvironment
  ) throws -> Type {
    var state = ParsingState(source: self)
    guard let expr = exprParser.parse(&state) else {
      throw ParsingError.unknown(startIndex..<endIndex)
    }

    return try expr.content.content.infer(environment)
  }
}

infix operator -->

/// A shorthand version of `Type.arrow`
func --> (arguments: [Type], returned: Type) -> Type {
  Type.arrow(arguments, returned)
}

/// A shorthand version of `Type.arrow` for single argument functions
func --> (argument: Type, returned: Type) -> Type {
  Type.arrow([argument], returned)
}

final class SyntaxInferenceTests: XCTestCase {
  func testApplication() throws {
    let e = DeclEnvironment(functions: [
      "increment": .init(.int32 --> .int32),
      "stringify": .init(.int32 --> .string),
    ])

    try XCTAssertNoDifference("increment(0)".inferParsedExpr(environment: e), .int32)
    try XCTAssertNoDifference("stringify(0)".inferParsedExpr(environment: e), .string)
    XCTAssertThrowsError(try "increment(false)".inferParsedExpr(environment: DeclEnvironment()))
    XCTAssertThrowsError(try "increment(false)".inferParsedExpr(environment: e))
  }

  func testClosure() throws {
    let e = DeclEnvironment(functions: [
      "increment": .init(.int32 --> .int32),
      "stringify": .init(.int32 --> .string),
      "decode": .init(.string --> .int32),
    ])

    XCTAssertNoDifference(
      try
        """
        { x in decode(stringify(increment(x))) }
        """
        .inferParsedExpr(environment: e), .int32 --> .int32
    )

    assertError(
      try
        """
        { x in stringify(decode(increment(x))) }
        """.inferParsedExpr(environment: e),
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
    let e = DeclEnvironment(functions: [
      "sum": .init([.int32, .int32] --> .int32),
      "stringify": .init([.int32, .int32] --> .string),
      "decode": .init([.string, .string] --> .int32),
    ])

    XCTAssertNoDifference(
      try
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
        """.inferParsedExpr(environment: e), [.int32, .int32] --> .int32
    )
  }

  func testClosureWithMultipleArgumentsDifferentTypes() throws {
    let e = DeclEnvironment(functions: [
      "concatenate": .init([.int32, .string] --> .string),
      "sum": .init([.int32, .int32] --> .int32),
      "decode": .init([.string, .int32] --> .int32),
    ])

    XCTAssertNoDifference(
      try
        """
        { str, int in
          decode(
            concatenate(int, str),
            sum(int, int)
          )
        }
        """.inferParsedExpr(environment: e),
      [.string, .int32] --> .int32
    )
  }

  func testMember() throws {
    let e = DeclEnvironment(types: [
      "String": .init(bindings: [
        "appending": .init(.string --> .string),
        "count": .init(.int32),
      ]),
    ])

    XCTAssertNoDifference(
      try #""Hello, ".appending("World!")"#.inferParsedExpr(environment: e),
      .string
    )
    XCTAssertNoDifference(
      try #""Test".count"#.inferParsedExpr(environment: e),
      .int32
    )
    assertError(
      try #""Test".description"#.inferParsedExpr(environment: e),
      TypeError.unknownMember("String", "description")
    )
  }

  func testMemberOfMember() throws {
    let e = DeclEnvironment(types: [
      "String": .init(bindings: [
        "count": .init(.int32),
      ]),
      "Int32": .init(bindings: [
        "magnitude": .init(.int32),
      ]),
    ])

    XCTAssertNoDifference(
      try #""Test".count.magnitude"#.inferParsedExpr(environment: e),
      .int32
    )
    assertError(
      try #""Test".magnitude.count"#.inferParsedExpr(environment: e),
      TypeError.unknownMember("String", "magnitude")
    )
  }

  func testIfThenElse() throws {
    let m: TypeEnvironment = [
      "Int32": .init(bindings: [
        "isInteger": .init(.bool),
        "isIntegerFunc": .init([] --> .bool),
        "toDouble": .init([] --> .double),
      ]),
    ]

    let e: BindingEnvironment = [
      "foo": .init(.bool),
      "bar": .init(.double),
      "baz": .init(.double),
      "fizz": .init(.int32),
    ]

    XCTAssertNoDifference(
      try #"if true { "true" } else { "false" } "#.inferParsedExpr(environment: .init(types: m)),
      .string
    )
    XCTAssertNoDifference(
      try #"if foo { bar } else { baz }  "#.inferParsedExpr(environment: .init(bindings: e, types: m)),
      .double
    )
    XCTAssertNoDifference(
      try
        #"""
        if 42.isInteger {
          "is integer"
        } else {
          "is not integer"
        }
        """#.inferParsedExpr(environment: .init(bindings: e, types: m)),
      .string
    )
    XCTAssertNoDifference(
      try
        #"""
        if 42.isIntegerFunc() {
          "is integer"
        } else {
          "is not integer"
        }
        """#.inferParsedExpr(environment: .init(bindings: e, types: m)),
      .string
    )
    assertError(
      try
        #"""
        if 42.toDouble() {
          "is integer"
        } else {
          "is not integer"
        }
        """#.inferParsedExpr(environment: .init(types: m)),
      TypeError.unificationFailure(.double, .bool)
    )
    assertError(
      try
        #"""
        if 42 {
          "is integer"
        } else {
          "is not integer"
        }
        """#.inferParsedExpr(environment: .init(types: m)),
      TypeError.unificationFailure(.int32, .bool)
    )
  }
}

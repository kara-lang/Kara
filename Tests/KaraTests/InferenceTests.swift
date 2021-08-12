//
//  Created by Max Desiatov on 16/04/2019.
//

@testable import AST
@testable import Types
import XCTest

final class InferenceTests: XCTestCase {
  func testTernary() throws {
    let string = Expr.ternary(
      .literal(true),
      .literal("then"),
      .literal("else")
    )
    let int = Expr.ternary(
      .literal(.bool(false)),
      .literal(0),
      .literal(42)
    )
    let error = Expr.ternary(
      .literal(true),
      .literal("then"),
      .literal(42)
    )

    XCTAssertEqual(try string.infer(), .string)
    XCTAssertEqual(try int.infer(), .int)
    XCTAssertThrowsError(try error.infer())
  }

  func testApplication() throws {
    let increment = "increment" <| .literal(0)
    let stringify = "stringify" <| .literal(0)
    let error = "increment" <| .literal(false)

    let e: Environment = [
      "increment": .init(.int --> .int),
      "stringify": .init(.int --> .string),
    ]

    XCTAssertEqual(try increment.infer(environment: e), .int)
    XCTAssertEqual(try stringify.infer(environment: e), .string)
    XCTAssertThrowsError(try error.infer())
  }

  func testLambda() throws {
    let lambda = Expr.lambda(
      ["x"],
      "decode" <| "stringify" <| "increment" <| "x"
    )

    let error = Expr.lambda(
      ["x"],
      "stringify" <| "decode" <| "increment" <| "x"
    )

    let e: Environment = [
      "increment": .init(.int --> .int),
      "stringify": .init(.int --> .string),
      "decode": .init(.string --> .int),
    ]

    XCTAssertEqual(try lambda.infer(environment: e), .int --> .int)
    XCTAssertThrowsError(try error.infer())
  }

  //  func testLambdaWithMultipleArguments() throws {
//    let lambda = Expr.lambda(
//      ["x", "y"],
//      .application(
//        "decode",
//            .application(
//                .application(
//                    "stringify",
//                    .application(.application("sum", "x"), "y")
//                ),
//                .application(.application("sum", "x"), "y")
//            )
//          ),
//            .application(
//          .application(
//            "stringify",
//                .application(.application("sum", "x"), "y")
//                    ),
//                .application(.application("sum", "x"), "y")
//            )
//          )
//      )
//    )
//
//    let e: Environment = [
//      "sum": [.init(.int --> .int --> .int)],
//      "stringify": [.init(.int --> .int --> .string)],
//      "decode": [.init(.string --> .string --> .int)],
//    ]
//
//    XCTAssertEqual(try lambda.infer(environment: e), .int --> .int --> .int)
  //  }

//    func testLambdaWithMultipleArgumentsDifferentTypes() throws {
//        let lambda = Expr.lambda(
//            ["str", "int"],
//            ("decode" <| (("concatenate" <| "int") <| "str")) <| (("sum" <| "int") <| "int")
//        )
//
//        let e: Environment = [
//            "concatenate": .init(.int --> .string --> .string),
//            "sum": .init(.int --> .int --> .int),
//            "decode": .init(.string --> .int --> .int),
//        ]
//
//        XCTAssertEqual(
//            try lambda.infer(environment: e),
//            .string --> .int --> .int
//        )
//    }

  func testLambdaApplication() throws {
    let lambda = Expr.application(
      .lambda(["x"], .ternary("x", .literal(1), .literal(0))), .literal(true)
    )

    let error = Expr.application(
      .lambda(["x"], .ternary("x", .literal(1), .literal(0))), .literal("blah")
    )

    XCTAssertEqual(try lambda.infer(), .int)
    XCTAssertThrowsError(try error.infer())
  }

  func testMember() throws {
    let appending = Expr.application(
      .member(.literal("Hello, "), "appending"),
      .literal(" World")
    )
    let count = Expr.member(.literal("Test"), "count")

    let m: Members = [
      "String": [
        "appending": .init(.string --> .string),
        "count": .init(.int),
      ],
    ]

    XCTAssertEqual(try appending.infer(members: m), .string)
    XCTAssertEqual(try count.infer(members: m), .int)
  }

  func testMemberOfMember() throws {
    let literal = Expr.literal("Test")
    let magnitude = Expr.member(.member(literal, "count"), "magnitude")
    let error = Expr.member(.member(literal, "magnitude"), "count")

    let m: Members = [
      "String": [
        "count": .init(.int),
      ],
      "Int": [
        "magnitude": .init(.int),
      ],
    ]

    XCTAssertEqual(try magnitude.infer(members: m), .int)
    XCTAssertThrowsError(try error.infer(members: m))
  }

  func testLambdaMember() throws {
    let lambda = Expr.application(
      .lambda(["x"], .ternary("x", .literal("one"), .literal("zero"))),
      .literal(true)
    )
    let count = Expr.member(lambda, "count")
    let error = Expr.member(lambda, "magnitude")

    let m: Members = [
      "String": [
        "count": .init(.int),
      ],
      "Int": [
        "magnitude": .init(.int),
      ],
    ]

    XCTAssertEqual(try count.infer(members: m), .int)
    XCTAssertThrowsError(try error.infer(members: m))
  }
}

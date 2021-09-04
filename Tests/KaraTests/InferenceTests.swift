//
//  Created by Max Desiatov on 16/04/2019.
//

@testable import Syntax
@testable import TypeInference
import XCTest

final class InferenceTests: XCTestCase {
//  func testLambdaApplication() throws {
//    let lambda = Expr.application(
//      .lambda(
//        .init(
//          identifiers: ["x"],
//          body: .ternary("x", .literal(1), .literal(0))
//        )
//      ),
//      [.literal(true)]
//    )
//
//    let error = Expr.application(
//      .lambda(.init(identifiers: ["x"], body: .ternary("x", .literal(1), .literal(0)))),
//      [.literal("blah")]
//    )
//
//    XCTAssertEqual(try lambda.infer(), .int)
//    XCTAssertThrowsError(try error.infer())
//  }
//
//
//  func testLambdaMember() throws {
//    let lambda = Expr.application(
//      .lambda(
//        .init(identifiers: ["x"], body: .ternary("x", .literal("one"), .literal("zero")))
//      ),
//      [.literal(true)]
//    )
//    let count = Expr.member(lambda, "count")
//    let error = Expr.member(lambda, "magnitude")
//
//    let m: Members = [
//      "String": [
//        "count": [.init(.int)],
//      ],
//      "Int": [
//        "magnitude": [.init(.int)],
//      ],
//    ]
//
//    XCTAssertEqual(try count.infer(members: m), .int)
//    XCTAssertThrowsError(try error.infer(members: m))
//  }

//  func testTupleMember() throws {
//    let tuple = Expr.tuple(.init([.literal(42), .literal("forty two")]))
//
//    XCTAssertEqual(try Expr.member(tuple, "0").infer(), .int)
//    XCTAssertEqual(try Expr.member(tuple, "1").infer(), .string)
//    XCTAssertThrowsError(try Expr.member(tuple, "2").infer())
//  }
//
//
//  func testOverload() throws {
//    // FIXME: correctly handle overloads for default arguments, other overloads should be banned
//    let uint = Type.constructor("UInt", [])
//
//    let count = Expr.member(.application("f", []), "count")
//    let magnitude = Expr.member(.application("f", []), "magnitude")
//    let error = Expr.member(
//      .application(
//        "f",
//        [.tuple(
//          .init(
//            [.literal("blah")]
//          )
//        )]
//      ), "count"
//    )
//
//    let m: Members = [
//      "String": [
//        "count": [.init(.int)],
//      ],
//      "Int": [
//        "magnitude": [.init(uint)],
//      ],
//    ]
//    let e: Environment = [
//      "f": [
//        .init([] --> .int),
//        .init([] --> .string),
//      ],
//    ]
//
//    XCTAssertEqual(try count.infer(environment: e, members: m), .int)
//    XCTAssertEqual(try magnitude.infer(environment: e, members: m), uint)
//    XCTAssertThrowsError(try error.infer(environment: e, members: m))
//  }

//  func testNestedOverload() throws {
//    let uint = Type.constructor("UInt", [])
//    let a = Type.constructor("A", [])
//    let b = Type.constructor("B", [])
//
//    let magnitude = Expr.member(
//      .member(.application("f", []), "a"),
//      "magnitude"
//    )
//    let count = Expr.member(
//      .member(.application("f", []), "b"),
//      "count"
//    )
//    let ambiguousCount = Expr.member(
//      .member(.application("f", []), "ambiguous"),
//      "count"
//    )
//    let ambiguousMagnitude = Expr.member(
//      .member(.application("f", []), "ambiguous"),
//      "magnitude"
//    )
//    let ambiguous = Expr.member(.application("f", []), "ambiguous")
//    let error = Expr.member(
//      .member(.application("f", []), "ambiguous"),
//      "ambiguous"
//    )
//
//    let m: Members = [
//      "A": [
//        "a": [.init(.int)],
//        "ambiguous": [.init(.string)],
//      ],
//      "B": [
//        "b": [.init(.string)],
//        "ambiguous": [.init(.int)],
//      ],
//      "String": [
//        "count": [.init(.int)],
//      ],
//      "Int": [
//        "magnitude": [.init(uint)],
//      ],
//    ]
//    let e: Environment = [
//      "f": [
//        .init([] --> a),
//        .init([] --> b),
//      ],
//    ]
//
//    XCTAssertEqual(try count.infer(environment: e, members: m), .int)
//    XCTAssertEqual(try magnitude.infer(environment: e, members: m), uint)
//    XCTAssertEqual(try ambiguousCount.infer(environment: e, members: m), .int)
//    XCTAssertEqual(
//      try ambiguousMagnitude.infer(environment: e, members: m),
//      uint
//    )
//    XCTAssertThrowsError(try ambiguous.infer(environment: e, members: m))
//    XCTAssertThrowsError(try error.infer(environment: e, members: m))
//  }
}

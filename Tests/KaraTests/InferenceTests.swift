//
//  Created by Max Desiatov on 16/04/2019.
//

@testable import Syntax
@testable import TypeChecker
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
}

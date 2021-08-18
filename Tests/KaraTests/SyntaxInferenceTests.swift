//
//  Created by Max Desiatov on 18/08/2021.
//

@testable import Syntax
@testable import Types
import XCTest

final class SyntaxInferenceTests: XCTestCase {
  func testApplication() throws {
    let increment = try XCTUnwrap(exprParser.parse("increment(0)"))
    let stringify = try XCTUnwrap(exprParser.parse("stringify(0)"))
    let error = try XCTUnwrap(exprParser.parse("increment(false)"))

    let e: Environment = [
      "increment": [.init(.int --> .int)],
      "stringify": [.init(.int --> .string)],
    ]

    XCTAssertEqual(try increment.infer(environment: e), .int)
    XCTAssertEqual(try stringify.infer(environment: e), .string)
    XCTAssertThrowsError(try error.infer())
  }
}

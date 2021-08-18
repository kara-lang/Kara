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
}

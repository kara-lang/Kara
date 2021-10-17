//
//  Created by Max Desiatov on 17/10/2021.
//

import CustomDump
import Syntax
@testable import TypeChecker
import XCTest

final class EvalTests: XCTestCase {
  func testEval() throws {
    let e = DeclEnvironment()
    try XCTAssertNoDifference(Expr.literal(5).eval(e), .literal(5))
  }
}

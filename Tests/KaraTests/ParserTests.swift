//
//  Created by Max Desiatov on 11/08/2021.
//

@testable import AST
import XCTest

final class ParserTests: XCTestCase {
  func testLiterals() throws {
    XCTAssertEqual(literalParser.parse("123"), 123)
    XCTAssertEqual(literalParser.parse("true"), true)

    XCTAssertEqual(literalParser.parse("false"), false)

    XCTAssertEqual(literalParser.parse(#""blah""#), "blah")

    XCTAssertEqual(literalParser.parse("3.14"), 3.14)
  }
}

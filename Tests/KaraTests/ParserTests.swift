//
//  Created by Max Desiatov on 11/08/2021.
//

@testable import AST
import Parsing
import XCTest

final class ParserTests: XCTestCase {
  func testLiterals() throws {
    XCTAssertEqual(literalParser.parse("123"), 123)
    XCTAssertEqual(literalParser.parse("true"), true)
    XCTAssertEqual(literalParser.parse("false"), false)
    XCTAssertEqual(literalParser.parse(#""string""#), "string")
    XCTAssertEqual(literalParser.parse("3.14"), 3.14)
  }

  func testStructs() throws {
    XCTAssertEqual(
      structParser.parse("struct Foo {}"),
      StructDecl(name: "Foo", genericParameters: [])
    )
    XCTAssertEqual(
      structParser.parse("struct Bar{}"),
      StructDecl(name: "Bar", genericParameters: [])
    )
    XCTAssertEqual(structParser.parse("""
    struct
    Baz
    {
    }
    """), StructDecl(name: "Baz", genericParameters: []))
    XCTAssertNil(structParser.parse("structBlorg{}"))
  }

  func testWhitespaces() throws {
    var input = ""[...].utf8
    XCTAssertNotNil(Whitespace().parse(&input))
    XCTAssertNotNil(whitespaceParser.parse("string"))
    XCTAssertNotNil(whitespaceParser.parse("  "))
    XCTAssertNotNil(whitespaceParser.parse("""

    """))
    XCTAssertNil(requiredWhitespaceParser.parse(""))
  }

  func testIdentifiers() {
    XCTAssertNil(identifierParser.parse("123abc"))
    XCTAssertEqual(identifierParser.parse("abc123"), "abc123")
    XCTAssertEqual(identifierParser.parse("_abc123"), "_abc123")
  }

  func testTuple() {
    let intsTuple = Expr.tuple(.init([1, 2, 3].map(Expr.literal)))

    XCTAssertNil(exprParser.parse("(,)"))
    XCTAssertEqual(exprParser.parse("()"), .tuple(.init([])))
    XCTAssertEqual(exprParser.parse("(1 ,2 ,3 ,)"), intsTuple)
    XCTAssertEqual(exprParser.parse("(1,2,3,)"), intsTuple)
    XCTAssertEqual(exprParser.parse("(1,2,3)"), intsTuple)

    XCTAssertEqual(exprParser.parse("(1)"), Expr.tuple(.init([.literal(1)])))
    XCTAssertEqual(exprParser.parse(#"("foo")"#), Expr.tuple(.init([.literal("foo")])))
  }

  func testLambda() {
    XCTAssertEqual(exprParser.parse("{}"), .lambda(.init(body: .unit)))
    XCTAssertEqual(exprParser.parse("{ 1 }"), .lambda(.init(body: .literal(1))))
    XCTAssertEqual(
      exprParser.parse("{ x in 1 }"),
      .lambda(.init(identifiers: ["x"], body: .literal(1)))
    )
    XCTAssertEqual(
      exprParser.parse("{ x, y in 1 }"),
      .lambda(.init(identifiers: ["x", "y"], body: .literal(1)))
    )
    XCTAssertNil(exprParser.parse("{ x in y in 1 }"))
  }

  func testIdentifierExpr() {
    XCTAssertEqual(exprParser.parse("abc123"), "abc123")
  }
}

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
    let intsTuple = Expr.tuple([1, 2, 3].map(Expr.literal))

    XCTAssertNil(tupleParser.parse("(,)"))
    XCTAssertEqual(tupleParser.parse("()"), .tuple([].map(Expr.literal)))
    XCTAssertEqual(tupleParser.parse("(1 ,2 ,3 ,)"), intsTuple)
    XCTAssertEqual(tupleParser.parse("(1,2,3,)"), intsTuple)
    XCTAssertEqual(tupleParser.parse("(1,2,3)"), intsTuple)

    XCTAssertEqual(tupleParser.parse("(1)"), Expr.tuple([.literal(1)]))
    XCTAssertEqual(tupleParser.parse(#"("foo")"#), Expr.tuple([.literal("foo")]))
  }

  func testExpr() {
    XCTAssertEqual(exprParser.parse("abc123"), "abc123")
  }
}

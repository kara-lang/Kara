//
//  Created by Max Desiatov on 11/08/2021.
//

import Parsing
@testable import Syntax
import XCTest

final class ParserTests: XCTestCase {
  let multiParameterLambda = Expr.lambda(.init(identifiers: ["x", "y", "z"], body: .literal(1)))

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

    XCTAssertNil(exprParser.parse("(,)").output)
    XCTAssertEqual(exprParser.parse("()").output?.element, .tuple(.init([])))
    XCTAssertEqual(exprParser.parse("(1 ,2 ,3 ,)").output?.element, intsTuple)
    XCTAssertEqual(exprParser.parse("(1,2,3,)").output?.element, intsTuple)
    XCTAssertEqual(exprParser.parse("(1,2,3)").output?.element, intsTuple)

    XCTAssertEqual(exprParser.parse("(1)").output?.element, Expr.tuple(.init([.literal(1)])))
    XCTAssertEqual(exprParser.parse(#"("foo")"#).output?.element, Expr.tuple(.init([.literal("foo")])))
  }

  func testLambda() {
    let singleParamaterLambda = Expr.lambda(.init(identifiers: ["x"], body: .literal(1)))

    XCTAssertEqual(exprParser.parse("{}").output?.element, .lambda(.init(body: .unit)))
    XCTAssertEqual(exprParser.parse("{ 1 }").output?.element, .lambda(.init(body: .literal(1))))
    XCTAssertEqual(exprParser.parse("{1}").output?.element, .lambda(.init(body: .literal(1))))
    XCTAssertEqual(exprParser.parse("{ x in 1 }").output?.element, singleParamaterLambda)
    XCTAssertEqual(exprParser.parse("{x in 1}").output?.element, singleParamaterLambda)
    XCTAssertEqual(exprParser.parse("{xin1}").output?.element, .lambda(.init(body: "xin1")))

    XCTAssertEqual(exprParser.parse("{ x, y, z in 1 }").output?.element, multiParameterLambda)
    XCTAssertEqual(exprParser.parse("{ x,y,z in 1 }").output?.element, multiParameterLambda)
    XCTAssertEqual(exprParser.parse("{x,y,z in 1}").output?.element, multiParameterLambda)

    XCTAssertNil(exprParser.parse("{ x in y in 1 }"))
    XCTAssertNil(exprParser.parse("{x in1}"))
  }

  func testMemberAccess() {
    XCTAssertEqual(exprParser.parse("5.description").output?.element, .member(5, "description"))
    XCTAssertEqual(exprParser.parse("5  .description").output?.element, .member(5, "description"))
    XCTAssertEqual(
      exprParser.parse(
        """
        5
        .description
        """
      ).output?.element,
      .member(5, "description")
    )

    XCTAssertEqual(
      exprParser.parse("{x,y,z in 1}.description").output?.element,
      .member(multiParameterLambda, "description")
    )
    XCTAssertEqual(
      exprParser.parse("{x,y,z in 1}.description.description").output?.element,
      .member(.member(multiParameterLambda, "description"), "description")
    )
    XCTAssertEqual(
      exprParser.parse("( 1 , 2, 3 ).description").output?.element,
      .member(.tuple(.init([1, 2, 3])), "description")
    )
  }

  func testApplication() {
    let multiParameterApplication =
      Expr.application(.lambda(.init(identifiers: ["x", "y", "z"], body: "x")), [1, 2, 3])

    XCTAssertEqual(exprParser.parse("{x,y,z in x}(1,2,3)").output?.element, multiParameterApplication)
    XCTAssertEqual(exprParser.parse("{x,y,z in x} ( 1 , 2, 3 )").output?.element, multiParameterApplication)
    XCTAssertEqual(
      exprParser.parse("{x,y,z in x} ( 1 , 2, 3 ).description").output?.element,
      .member(multiParameterApplication, "description")
    )
  }

  func testIdentifierExpr() {
    XCTAssertEqual(exprParser.parse("abc123").output?.element, "abc123")
  }
}

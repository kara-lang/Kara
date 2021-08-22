//
//  Created by Max Desiatov on 11/08/2021.
//

import Parsing
import SnapshotTesting
@testable import Syntax
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
    assertSnapshot(structParser.parse("struct Foo {}"))
    assertSnapshot(structParser.parse("struct  Bar{}"))

    assertSnapshot(structParser.parse("""
    struct
    Baz
    {
    }
    """))

    XCTAssertNil(structParser.parse("structBlorg{}").output)
  }

  func testIdentifiers() {
    XCTAssertNil(identifierParser.parse("123abc").output)
    assertSnapshot(identifierParser.parse("abc123"))
    assertSnapshot(identifierParser.parse("_abc123"))
  }

  func testTuple() {
    XCTAssertNil(exprParser.parse("(,)").output)
    assertSnapshot(exprParser.parse("()"))
    assertSnapshot(exprParser.parse("(1 ,2 ,3 ,)"))
    assertSnapshot(exprParser.parse("(1,2,3,)"))
    assertSnapshot(exprParser.parse("(1,2,3)"))

    assertSnapshot(exprParser.parse("(1)"))
    assertSnapshot(exprParser.parse(#"("foo")"#))
  }

  func testClosure() {
    assertSnapshot(exprParser.parse("{}"))
    assertSnapshot(exprParser.parse("{ 1 }"))
    assertSnapshot(exprParser.parse("{1}"))
    assertSnapshot(exprParser.parse("{ x in 1 }"))
    assertSnapshot(exprParser.parse("{x in 1}"))
    assertSnapshot(exprParser.parse("{xin1}"))

    assertSnapshot(exprParser.parse("{ x, y, z in 1 }"))
    assertSnapshot(exprParser.parse("{ x,y,z in 1 }"))
    assertSnapshot(exprParser.parse("{x,y,z in 1}"))

    XCTAssertNil(exprParser.parse("{ x in y in 1 }").output)
    XCTAssertNil(exprParser.parse("{x in1}").output)
  }

//  func testMemberAccess() {
//    XCTAssertEqual(exprParser.parse("5.description").output?.element, .member(5, "description"))
//    XCTAssertEqual(exprParser.parse("5  .description").output?.element, .member(5, "description"))
//    XCTAssertEqual(
//      exprParser.parse(
//        """
//        5
//        .description
//        """
//      ).output?.element,
//      .member(5, "description")
//    )
//
//    XCTAssertEqual(
//      exprParser.parse("{x,y,z in 1}.description").output?.element,
//      .member(multiParameterLambda, "description")
//    )
//    XCTAssertEqual(
//      exprParser.parse("{x,y,z in 1}.description.description").output?.element,
//      .member(.member(multiParameterLambda, "description"), "description")
//    )
//    assertSnapshot(matching: exprParser.parse("( 1 , 2, 3 ).description").output, as: .dump)
//    XCTAssertEqual(
//      exprParser.parse("( 1 , 2, 3 ).description").output?.element,
//        .member(.tuple(.init(elements: [1, 2, 3])), "description")
//    )
//  }

//  func testApplication() {
//    let multiParameterApplication =
//      Expr.application(.closure(.init(identifiers: ["x", "y", "z"], body: "x")), [1, 2, 3])
//
//    XCTAssertEqual(exprParser.parse("{x,y,z in x}(1,2,3)").output?.element, multiParameterApplication)
//    XCTAssertEqual(exprParser.parse("{x,y,z in x} ( 1 , 2, 3 )").output?.element, multiParameterApplication)
//    XCTAssertEqual(
//      exprParser.parse("{x,y,z in x} ( 1 , 2, 3 ).description").output?.element,
//      .member(multiParameterApplication, "description")
//    )
//  }

  func testStatefulWhitespace() {
    let emptyString = ""
    var state = ParsingState(source: emptyString)
    let parser = StatefulWhitespace()

    XCTAssertNotNil(parser.parse(&state))

    XCTAssertEqual(
      state,
      ParsingState(source: emptyString, currentIndex: emptyString.startIndex, currentColumn: 0, currentLine: 0)
    )

    let unixNewline = "\n"
    state = ParsingState(source: unixNewline)

    XCTAssertNotNil(parser.parse(&state))

    XCTAssertEqual(
      state,
      ParsingState(source: unixNewline, currentIndex: unixNewline.endIndex, currentColumn: 0, currentLine: 1)
    )

    let classicMacNewline = "\r"
    state = ParsingState(source: classicMacNewline)

    XCTAssertNotNil(parser.parse(&state))

    XCTAssertEqual(
      state,
      ParsingState(
        source: classicMacNewline,
        currentIndex: classicMacNewline.endIndex,
        currentColumn: 0,
        currentLine: 1
      )
    )

    let windowsNewline = "\r\n"
    state = ParsingState(source: windowsNewline)

    XCTAssertNotNil(parser.parse(&state))

    XCTAssertEqual(
      state,
      ParsingState(
        source: windowsNewline,
        currentIndex: windowsNewline.endIndex,
        currentColumn: 0,
        currentLine: 1
      )
    )

    let trailingCharacters = "  \r\n  foo"
    state = ParsingState(source: trailingCharacters)

    XCTAssertNotNil(parser.parse(&state))

    XCTAssertEqual(
      state,
      ParsingState(
        source: trailingCharacters,
        currentIndex: trailingCharacters.firstIndex(of: "f")!,
        currentColumn: 2,
        currentLine: 1
      )
    )

    let noWhitespaces = "bar"
    state = ParsingState(source: noWhitespaces)

    XCTAssertNotNil(parser.parse(&state))

    XCTAssertEqual(
      state,
      ParsingState(
        source: noWhitespaces,
        currentIndex: noWhitespaces.startIndex,
        currentColumn: 0,
        currentLine: 0
      )
    )
  }

  func testRequiredWhitespace() {
    let emptyString = ""
    var state = ParsingState(source: emptyString)
    let parser = StatefulWhitespace(isRequired: true)

    XCTAssertNil(parser.parse(&state))

    XCTAssertEqual(
      state,
      ParsingState(source: emptyString, currentIndex: emptyString.startIndex, currentColumn: 0, currentLine: 0)
    )

    let unixNewline = "\n"
    state = ParsingState(source: unixNewline)

    XCTAssertNotNil(parser.parse(&state))

    XCTAssertEqual(
      state,
      ParsingState(source: unixNewline, currentIndex: unixNewline.endIndex, currentColumn: 0, currentLine: 1)
    )

    let classicMacNewline = "\r"
    state = ParsingState(source: classicMacNewline)

    XCTAssertNotNil(parser.parse(&state))

    XCTAssertEqual(
      state,
      ParsingState(
        source: classicMacNewline,
        currentIndex: classicMacNewline.endIndex,
        currentColumn: 0,
        currentLine: 1
      )
    )

    let windowsNewline = "\r\n"
    state = ParsingState(source: windowsNewline)

    XCTAssertNotNil(parser.parse(&state))

    XCTAssertEqual(
      state,
      ParsingState(
        source: windowsNewline,
        currentIndex: windowsNewline.endIndex,
        currentColumn: 0,
        currentLine: 1
      )
    )

    let trailingCharacters = "  \r\n  foo"
    state = ParsingState(source: trailingCharacters)

    XCTAssertNotNil(parser.parse(&state))

    XCTAssertEqual(
      state,
      ParsingState(
        source: trailingCharacters,
        currentIndex: trailingCharacters.firstIndex(of: "f")!,
        currentColumn: 2,
        currentLine: 1
      )
    )

    let noWhitespaces = "bar"
    state = ParsingState(source: noWhitespaces)

    XCTAssertNil(parser.parse(&state))

    XCTAssertEqual(
      state,
      ParsingState(
        source: noWhitespaces,
        currentIndex: noWhitespaces.startIndex,
        currentColumn: 0,
        currentLine: 0
      )
    )
  }
}

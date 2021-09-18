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

    assertSnapshot(exprParser.parse(#"("foo", ("bar", "baz"))"#))
    assertSnapshot(exprParser.parse(#"("foo", ("bar", "baz", (1, "fizz")))"#))

    XCTAssertNil(exprParser.parse(#"("foo", ("bar", "baz", (1, "fizz"))"#).output)

    XCTAssertNil(exprParser.parse(#"("foo", ("bar")"#).output)
  }

  func testIfThenElse() {
    assertSnapshot(exprParser.parse(#"if true { "true" } else { "false" }"#))
    assertSnapshot(exprParser.parse(#"if foo { bar } else { baz }"#))
    assertSnapshot(
      exprParser.parse(
        #"""
        if 42.isInteger {
          "is integer"
        } else {
          "is not integer"
        }
        """#
      )
    )
    assertSnapshot(
      exprParser.parse(
        #"""
        if 42.isInteger() {
          "is integer"
        } else {
          "is not integer"
        }
        """#
      )
    )
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

  func testMemberAccess() {
    assertSnapshot(exprParser.parse("5.description"))
    assertSnapshot(exprParser.parse("5  .description"))
    assertSnapshot(
      exprParser.parse(
        """
        5
        .description
        """
      )
    )

    assertSnapshot(exprParser.parse("{x,y,z in 1}.description"))
    assertSnapshot(exprParser.parse("{x,y,z in 1}.description.description"))
    assertSnapshot(exprParser.parse("( 1 , 2, 3 ).description"))
    assertSnapshot(exprParser.parse("( 1, 2, 3 ).description"))
  }

  func testApplication() {
    assertSnapshot(exprParser.parse("{x,y,z in x}(1,2,3)"))
    assertSnapshot(exprParser.parse("{x,y,z in x} ( 1 , 2, 3 )"))
    assertSnapshot(exprParser.parse("{x,y,z in x} ( 1 , 2, 3 ).description"))
  }

  func testTypeConstructor() {
    assertSnapshot(typeParser.parse("Array<Int>"))
    assertNotFullyConsumed(typeParser.parse("Set<Double").rest)
    assertSnapshot(typeParser.parse("Dictionary <String, Bool>"))
    assertSnapshot(typeParser.parse("Result <String, IOError,>"))
    assertSnapshot(
      typeParser.parse(
        """
        Dictionary <String,
        Array<Bool>
        >
        """
      )
    )
  }

  func testTupleType() {
    assertSnapshot(typeParser.parse("(Int, Double, Bool)"))
    assertSnapshot(typeParser.parse("(Int, Double, Bool, String,)"))
    assertSnapshot(typeParser.parse("Array<(Int, String)>"))
    assertSnapshot(typeParser.parse("Array<(Int, String, Bool,)>"))
    assertSnapshot(typeParser.parse("Array<(Int, String, Bool,Dictionary<Double, Set<(Foo, Bar)>>)>"))
  }

  func testArrow() {
    assertSnapshot(typeParser.parse("Int -> Double"))
    assertSnapshot(typeParser.parse("Int -> Double -> String"))
    assertSnapshot(
      typeParser.parse(
        """
        Int ->
        Double ->
        String
        """
      )
    )
    assertSnapshot(typeParser.parse("(Int, Double) -> String"))
    assertSnapshot(typeParser.parse("Dictionary<Bool, (Int, Double, String)> -> Array<Character>"))
    assertSnapshot(typeParser.parse("Dictionary<Bool, (Int, Double, String)> -> (Array<Character>, Array<Bool>)"))
    assertNotFullyConsumed(typeParser.parse("Int -> ").rest)
    XCTAssertNil(typeParser.parse(" -> String").output)
  }

  func testFunctionDecl() {
    assertSnapshot(functionDeclParser.parse("func f(x: Int) -> Int { x }"))
    assertSnapshot(functionDeclParser.parse(#"func f(x y: Bool) -> String { if y { "x" } else { "not x" } }"#))
  }

  func testComments() {
    assertSnapshot(commentParser.parse("// Hello, world!"))
    assertSnapshot(commentParser.parse("/// Hello, world!"))
    assertSnapshot(commentParser.parse("/* Hello, world!*/"))
    assertSnapshot(commentParser.parse("/** Hello, world!*/"))
    assertSnapshot(
      commentParser.parse(
        """
        /* Hello, world!
        World, hello!
        */
        """
      )
    )
    assertSnapshot(
      commentParser.parse(
        """
        /** Hello, world!
        World, hello!
        More content here. */
        """
      )
    )
    assertSnapshot(
      commentParser.parse(
        """
        /** Hello, world!
        // Inner comment


                    More content here. */
        """
      )
    )
    XCTAssertNil(commentParser.parse("/* Hello, world!").output)
  }

  func testTrivia() {
    assertSnapshot(triviaParser.parse("// Hello, world!"))

    assertSnapshot(triviaParser.parse("   // Hello, world!"))
  }

  func testStatefulWhitespace() {
    let emptyString = ""
    var state = ParsingState(source: emptyString)
    let parser = statefulWhitespace()

    XCTAssertNotNil(parser.parse(&state))

    XCTAssertEqual(
      state,
      ParsingState(source: emptyString, index: emptyString.startIndex, column: 0, line: 0)
    )

    let unixNewline = "\n"
    state = ParsingState(source: unixNewline)

    XCTAssertNotNil(parser.parse(&state))

    XCTAssertEqual(
      state,
      ParsingState(source: unixNewline, index: unixNewline.endIndex, column: 0, line: 1)
    )

    let classicMacNewline = "\r"
    state = ParsingState(source: classicMacNewline)

    XCTAssertNotNil(parser.parse(&state))

    XCTAssertEqual(
      state,
      ParsingState(
        source: classicMacNewline,
        index: classicMacNewline.endIndex,
        column: 0,
        line: 1
      )
    )

    let windowsNewline = "\r\n"
    state = ParsingState(source: windowsNewline)

    XCTAssertNotNil(parser.parse(&state))

    XCTAssertEqual(
      state,
      ParsingState(
        source: windowsNewline,
        index: windowsNewline.endIndex,
        column: 0,
        line: 1
      )
    )

    let trailingCharacters = "  \r\n  foo"
    state = ParsingState(source: trailingCharacters)

    XCTAssertNotNil(parser.parse(&state))

    XCTAssertEqual(
      state,
      ParsingState(
        source: trailingCharacters,
        index: trailingCharacters.firstIndex(of: "f")!,
        column: 2,
        line: 1
      )
    )

    let noWhitespaces = "bar"
    state = ParsingState(source: noWhitespaces)

    XCTAssertNotNil(parser.parse(&state))

    XCTAssertEqual(
      state,
      ParsingState(
        source: noWhitespaces,
        index: noWhitespaces.startIndex,
        column: 0,
        line: 0
      )
    )
  }

  func testRequiredWhitespace() {
    let emptyString = ""
    var state = ParsingState(source: emptyString)
    let parser = statefulWhitespace(isRequired: true)

    XCTAssertNil(parser.parse(&state))

    XCTAssertEqual(
      state,
      ParsingState(source: emptyString, index: emptyString.startIndex, column: 0, line: 0)
    )

    let unixNewline = "\n"
    state = ParsingState(source: unixNewline)

    XCTAssertNotNil(parser.parse(&state))

    XCTAssertEqual(
      state,
      ParsingState(source: unixNewline, index: unixNewline.endIndex, column: 0, line: 1)
    )

    let classicMacNewline = "\r"
    state = ParsingState(source: classicMacNewline)

    XCTAssertNotNil(parser.parse(&state))

    XCTAssertEqual(
      state,
      ParsingState(
        source: classicMacNewline,
        index: classicMacNewline.endIndex,
        column: 0,
        line: 1
      )
    )

    let windowsNewline = "\r\n"
    state = ParsingState(source: windowsNewline)

    XCTAssertNotNil(parser.parse(&state))

    XCTAssertEqual(
      state,
      ParsingState(
        source: windowsNewline,
        index: windowsNewline.endIndex,
        column: 0,
        line: 1
      )
    )

    let trailingCharacters = "  \r\n  foo"
    state = ParsingState(source: trailingCharacters)

    XCTAssertNotNil(parser.parse(&state))

    XCTAssertEqual(
      state,
      ParsingState(
        source: trailingCharacters,
        index: trailingCharacters.firstIndex(of: "f")!,
        column: 2,
        line: 1
      )
    )

    let noWhitespaces = "bar"
    state = ParsingState(source: noWhitespaces)

    XCTAssertNil(parser.parse(&state))

    XCTAssertEqual(
      state,
      ParsingState(
        source: noWhitespaces,
        index: noWhitespaces.startIndex,
        column: 0,
        line: 0
      )
    )
  }
}

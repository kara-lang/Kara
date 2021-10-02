//
//  Created by Max Desiatov on 01/10/2021.
//

import CustomDump
import Parsing
import SnapshotTesting
@testable import Syntax
import XCTest

final class TriviaParsersTests: XCTestCase {
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

    XCTAssertNoDifference(
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

    XCTAssertNoDifference(
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

    XCTAssertNoDifference(
      state,
      ParsingState(source: emptyString, index: emptyString.startIndex, column: 0, line: 0)
    )

    let unixNewline = "\n"
    state = ParsingState(source: unixNewline)

    XCTAssertNotNil(parser.parse(&state))

    XCTAssertNoDifference(
      state,
      ParsingState(source: unixNewline, index: unixNewline.endIndex, column: 0, line: 1)
    )

    let classicMacNewline = "\r"
    state = ParsingState(source: classicMacNewline)

    XCTAssertNotNil(parser.parse(&state))

    XCTAssertNoDifference(
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

    XCTAssertNoDifference(
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

    XCTAssertNoDifference(
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

    XCTAssertNoDifference(
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

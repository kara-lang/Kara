//
//  Created by Max Desiatov on 22/08/2021.
//

import SnapshotTesting
@testable import Syntax
import XCTest

public extension Snapshotting where Format == String {
  /// A snapshot strategy that captures a value's textual description from `String`'s `init(description:)`
  /// initializer.
  static var debugDescription: Snapshotting {
    SimplySnapshotting.lines.pullback(String.init(reflecting:))
  }
}

func assertSnapshot<T>(
  _ parsingResult: (output: T?, rest: ParsingState),
  file: StaticString = #file,
  testName: String = #function,
  line: UInt = #line
) {
  guard let output = parsingResult.output else {
    XCTFail("No output from parser", file: file, line: line)
    return
  }
  assertFullyConsumed(parsingResult.rest, file: file, line: line)
  assertSnapshot(matching: output, as: .debugDescription, file: file, testName: testName, line: line)
}

func assertError<T, E: Error & Equatable>(
  _ expression: @autoclosure () throws -> T,
  file: StaticString = #filePath,
  line: UInt = #line,
  _ expectedError: E
) {
  do {
    _ = try expression()
    XCTFail("Did not throw an error", file: file, line: line)
  } catch {
    guard let error = error as? E else {
      XCTFail("Error value \(error) is of unexpected type", file: file, line: line)
      return
    }

    XCTAssertEqual(error, expectedError, file: file, line: line)
  }
}

func assertFullyConsumed(
  _ state: ParsingState,
  file: StaticString = #file,
  line: UInt = #line
) {
  guard state.index == state.source.utf8.endIndex else {
    return XCTFail(
      "Parser input unexpectedly not fully consumed, remaining: \(state.source[state.index...])",
      file: file,
      line: line
    )
  }
}

func assertNotFullyConsumed(
  _ state: ParsingState,
  file: StaticString = #file,
  line: UInt = #line
) {
  guard state.index != state.source.utf8.endIndex else {
    return XCTFail("Parser input unexpectedly fully consumed", file: file, line: line)
  }
}

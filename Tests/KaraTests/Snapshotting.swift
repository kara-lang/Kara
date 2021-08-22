//
//  Created by Max Desiatov on 22/08/2021.
//

import SnapshotTesting
import Syntax
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
  assertSnapshot(matching: output, as: .debugDescription, file: file, testName: testName, line: line)
}

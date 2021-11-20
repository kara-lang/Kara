//
//  Created by Max Desiatov on 22/08/2021.
//

import CustomDump
@testable import Driver
import KIR
import SnapshotTesting
@testable import Syntax
@testable import TypeChecker
import XCTest

public extension Snapshotting where Format == String {
  /// A snapshot strategy that captures a value's textual description from `String`'s `init(description:)`
  /// initializer.
  static var debugDescription: Snapshotting {
    SimplySnapshotting.lines.pullback(String.init(reflecting:))
  }
}

func assertJSSnapshot(
  _ source: String,
  file: StaticString = #file,
  testName: String = #function,
  line: UInt = #line
) {
  try assertSnapshot(matching: driverPass(source), as: .js, file: file, testName: testName, line: line)
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

  var stringDump = ""
  customDump(output, to: &stringDump)
  assertSnapshot(matching: stringDump, as: .lines, file: file, testName: testName, line: line)
}

func assertSnapshot(
  _ annotatedExpr: Expr<TypeAnnotation>,
  file: StaticString = #file,
  testName: String = #function,
  line: UInt = #line
) {
  var stringDump = ""
  customDump(annotatedExpr, to: &stringDump)
  assertSnapshot(matching: stringDump, as: .lines, file: file, testName: testName, line: line)
}

func assertError<T, E: Error & Equatable>(
  _ expression: @autoclosure () throws -> T,
  _ expectedError: E,
  file: StaticString = #filePath,
  line: UInt = #line
) {
  do {
    _ = try expression()
    XCTFail("Did not throw an error", file: file, line: line)
  } catch {
    guard let actualError = error as? E else {
      XCTFail("Error value \(error) is of unexpected type", file: file, line: line)
      return
    }

    XCTAssertNoDifference(actualError, expectedError, file: file, line: line)
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

func assertEval(
  _ source: ParsingState,
  _ kir: KIRExpr,
  file: StaticString = #file,
  line: UInt = #line
) throws {
  var source = source
  let parsingResult = exprParser().parse(&source)
  assertFullyConsumed(source)
  let e = ModuleEnvironment<EmptyAnnotation>()
  let annotated = try parsingResult?.content.content.annotate(e)
  try XCTAssertNoDifference(
    annotated?.eval(ModuleEnvironment<TypeAnnotation>()),
    kir,
    file: file,
    line: line
  )
}

func assertEvalThrows<E: Error & Equatable>(
  _ source: ParsingState,
  _ error: E,
  file: StaticString = #file,
  line: UInt = #line
) throws {
  var source = source
  let parsingResult = exprParser().parse(&source)
  assertFullyConsumed(source)
  let e = ModuleEnvironment<EmptyAnnotation>()
  try assertError(
    parsingResult?.content.content.annotate(e).eval(ModuleEnvironment<TypeAnnotation>()),
    error,
    file: file,
    line: line
  )
}

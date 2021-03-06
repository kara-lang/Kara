import CustomDump
import class Foundation.Bundle
import XCTest

final class KaraTests: XCTestCase {
  // FIXME: re-enable this test on Windows after this SAP bug is
  // fixed https://github.com/apple/swift-argument-parser/issues/369
  #if !os(Windows)
  func testExample() throws {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct
    // results.

    // Some of the APIs that we use below are available in macOS 10.13 and above.
    guard #available(macOS 10.13, *) else {
      return
    }

    // Mac Catalyst won't have `Process`, but it is supported for executables.
    #if !targetEnvironment(macCatalyst)

    let fooBinary = productsDirectory.appendingPathComponent("kara")

    let process = Process()
    process.executableURL = fooBinary

    let pipe = Pipe()
    process.standardOutput = pipe

    try process.run()
    process.waitUntilExit()

    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(data: data, encoding: .utf8)

    XCTAssertNoDifference(
      output,
      """
      OVERVIEW: Kara is a type-safe general purpose programming language.

      USAGE: kara <subcommand>

      OPTIONS:
        --version               Show the version.
        -h, --help              Show help information.

      SUBCOMMANDS:
        run
        lsp

        See 'kara help <subcommand>' for detailed help.

      """
    )
    #endif
  }

  /// Returns path to the built products directory.
  var productsDirectory: URL {
    #if os(macOS)
    for bundle in Bundle.allBundles where bundle.bundlePath.hasSuffix(".xctest") {
      return bundle.bundleURL.deletingLastPathComponent()
    }
    fatalError("couldn't find the products directory")
    #else
    return Bundle.main.bundleURL
    #endif
  }
  #endif
}

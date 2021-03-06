// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "Kara",
  platforms: [.macOS(.v10_15)],
  dependencies: [
    // Dependencies declare other packages that this package depends on.
    .package(
      url: "https://github.com/apple/swift-argument-parser.git",
      .upToNextMinor(from: "0.5.0")
    ),
    .package(
      name: "Benchmark",
      url: "https://github.com/google/swift-benchmark.git",
      from: "0.1.1"
    ),
    .package(
      name: "swift-parsing",
      url: "https://github.com/pointfreeco/swift-parsing.git",
      .upToNextMinor(from: "0.4.1")
    ),
    .package(
      url: "https://github.com/pointfreeco/swift-snapshot-testing.git",
      .branch("main")
    ),
    .package(url: "https://github.com/pointfreeco/swift-custom-dump.git", from: "0.3.0"),
//    .package(path: "../LLVMSwift"),
  ],
  targets: [
    // Targets are the basic building blocks of a package. A target can define a module or a test
    // suite. Targets can depend on other targets in this package, and on products in packages this
    // package depends on.
    .target(
      name: "Basic",
      dependencies: []
    ),
    .target(
      name: "Syntax",
      dependencies: [
        "Basic",
        .product(name: "Parsing", package: "swift-parsing"),
      ]
    ),
    .target(
      name: "KIR",
      dependencies: [
        "Syntax",
      ]
    ),
    .target(
      name: "TypeChecker",
      dependencies: ["KIR", "Syntax"]
    ),
    .target(
      name: "JSCodegen",
      dependencies: ["Basic", "Syntax", "TypeChecker"]
    ),
    .target(
      name: "Driver",
      dependencies: [
        "Syntax",
        "TypeChecker",
        "JSCodegen",
      ]
    ),

    // jsonrpc: LSP connection using jsonrpc over pipes.
    .target(
      name: "LanguageServerProtocolJSONRPC",
      dependencies: ["LanguageServerProtocol", "LSPLogging"]
    ),

    // LanguageServerProtocol: The core LSP types, suitable for any LSP implementation.
    .target(
      name: "LanguageServerProtocol",
      dependencies: []
    ),

    // Logging support used in LSP modules.
    .target(
      name: "LSPLogging",
      dependencies: []
    ),

    .target(
      name: "LSPServer",
      dependencies: ["Driver", "LanguageServerProtocolJSONRPC"]
    ),

    .executableTarget(
      name: "kara",
      dependencies: [
        "Driver",
        "LSPServer",
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
      ]
    ),
    .executableTarget(
      name: "kara-benchmark",
      dependencies: ["Benchmark"]
    ),
    .testTarget(
      name: "KaraTests",
      dependencies: [
        "Driver",
        .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
        .product(name: "CustomDump", package: "swift-custom-dump"),
      ],
      exclude: ["__Snapshots__"]
    ),
  ]
)

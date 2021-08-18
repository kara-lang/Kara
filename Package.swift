// swift-tools-version:5.4
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "Kara",
  platforms: [.macOS(.v10_14)],
  dependencies: [
    // Dependencies declare other packages that this package depends on.
    .package(
      url: "https://github.com/apple/swift-argument-parser.git",
      .upToNextMinor(from: "0.4.0")
    ),
    .package(
      name: "Benchmark",
      url: "https://github.com/google/swift-benchmark.git",
      from: "0.1.0"
    ),
    .package(url: "https://github.com/llvm-swift/FileCheck.git", from: "0.2.5"),
    .package(
      name: "swift-parsing",
      url: "https://github.com/pointfreeco/swift-parsing.git",
      from: "0.1.2"
    ),
  ],
  targets: [
    // Targets are the basic building blocks of a package. A target can define a module or a test
    // suite. Targets can depend on other targets in this package, and on products in packages this
    // package depends on.
    .target(
      name: "Syntax",
      dependencies: [
        .product(name: "Parsing", package: "swift-parsing"),
      ]
    ),
    .target(
      name: "Types",
      dependencies: [
        "Syntax",
      ]
    ),
    .executableTarget(
      name: "kara",
      dependencies: [
        "Types",
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
      ]
    ),
    .executableTarget(
      name: "kara-benchmark",
      dependencies: [
        "Benchmark",
      ]
    ),
    .testTarget(
      name: "KaraTests",
      dependencies: [
        "Syntax",
        "Types",
        "FileCheck",
      ],
      exclude: ["Fixtures"]
    ),
  ]
)

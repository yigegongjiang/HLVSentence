// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "HLVSentence",
    platforms: [
      .macOS(.v13),
    ],
    products: [
      .library(name: "HLVSentence", targets: ["HLVSentence"]),
      .executable(name: "hlvst", targets: ["HLVSTCommand"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.0"),
        .package(url: "https://github.com/yigegongjiang/HLVFileDump.git", .upToNextMajor(from: "1.0.0")),
        .package(url: "https://github.com/johnxnguyen/Down.git", .upToNextMajor(from: "0.1.0")),
        .package(url: "https://github.com/kareman/SwiftShell.git", .upToNextMajor(from: "5.0.0"))
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
          name: "HLVSentence",
          dependencies: [
            "HLVFileDump",
            "SwiftShell",
          ]
        ),
        .executableTarget(
            name: "HLVSTCommand",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .target(name: "HLVSentence"),
                "HLVFileDump",
                "Down",
            ]
        ),
    ]
)

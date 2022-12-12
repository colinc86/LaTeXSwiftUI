// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "LaTeXSwiftUI",
  platforms: [
    .iOS(.v16),
    .macOS(.v13)
  ],
  products: [
    .library(
      name: "LaTeXSwiftUI",
      targets: ["LaTeXSwiftUI"]),
  ],
  dependencies: [
     .package(url: "https://github.com/colinc86/MathJaxSwift", branch: "develop"),
     .package(url: "https://github.com/exyte/SVGView", from: "1.0.4"),
     .package(url: "https://github.com/kean/Nuke", from: "11.3.1"),
     .package(url: "https://github.com/apple/swift-log", from: "1.4.4"),
     .package(url: "https://github.com/Kitura/swift-html-entities", from: "4.0.1")
  ],
  targets: [
    .target(
      name: "LaTeXSwiftUI",
      dependencies: [
        "MathJaxSwift",
        "SVGView",
        "Nuke",
        .product(name: "Logging", package: "swift-log"),
        .product(name: "HTMLEntities", package: "swift-html-entities")
      ]),
    .testTarget(
      name: "LaTeXSwiftUITests",
      dependencies: ["LaTeXSwiftUI"]),
  ]
)

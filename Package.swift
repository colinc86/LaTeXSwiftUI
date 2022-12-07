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
     .package(url: "https://github.com/colinc86/MathJaxSwift", branch: "main"),
     .package(url: "https://github.com/swhitty/SwiftDraw", from: "0.13.2")
  ],
  targets: [
    .target(
      name: "LaTeXSwiftUI",
      dependencies: [
        "MathJaxSwift",
        "SwiftDraw"
      ]),
    .testTarget(
      name: "LaTeXSwiftUITests",
      dependencies: ["LaTeXSwiftUI"]),
  ]
)

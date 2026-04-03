// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "LaTeXSwiftUI",
  platforms: [
    .iOS(.v15),
    .macOS(.v12),
    .visionOS(.v1)
  ],
  products: [
    .library(
      name: "LaTeXSwiftUI",
      targets: ["LaTeXSwiftUI"]),
  ],
  dependencies: [
     .package(url: "https://github.com/colinc86/MathJaxSwift", from: "3.5.0"),
     .package(url: "https://github.com/swhitty/SwiftDraw", from: "0.27.0"),
     .package(url: "https://github.com/Kitura/swift-html-entities", from: "4.0.1")
  ],
  targets: [
    .target(
      name: "LaTeXSwiftUI",
      dependencies: [
        "MathJaxSwift",
        "SwiftDraw",
        .product(name: "HTMLEntities", package: "swift-html-entities")
      ],
      resources: [
        .copy("PrivacyInfo.xcprivacy")
      ]),
    .testTarget(
      name: "LaTeXSwiftUITests",
      dependencies: ["LaTeXSwiftUI"]),
  ]
)

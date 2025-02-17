//
//  ReplacerTests.swift
//  LaTeXSwiftUI
//
//  Created by Colin Campbell on 2/16/25.
//

import MathJaxSwift
import XCTest
@testable import LaTeXSwiftUI

final class ReplacerTests: XCTestCase {
  
  func testReplace_Ampersand() {
    let input = "\\&"
    let output = Replacer.replace(input)
    XCTAssertEqual(output, "&")
  }
  
  func testReplace_Percent() {
    let input = "\\%"
    let output = Replacer.replace(input)
    XCTAssertEqual(output, "%")
  }
  
  func testReplace_Dollar() {
    let input = "\\$"
    let output = Replacer.replace(input)
    XCTAssertEqual(output, "$")
  }
  
  func testReplace_Pound() {
    let input = "\\#"
    let output = Replacer.replace(input)
    XCTAssertEqual(output, "#")
  }
  
  func testReplace_Underscore() {
    let input = "\\_"
    let output = Replacer.replace(input)
    XCTAssertEqual(output, "_")
  }
  
  func testReplace_LeftBrace() {
    let input = "\\{"
    let output = Replacer.replace(input)
    XCTAssertEqual(output, "{")
  }
  
  func testReplace_RightBrace() {
    let input = "\\}"
    let output = Replacer.replace(input)
    XCTAssertEqual(output, "}")
  }
  
  func testReplace_Tilde() {
    let input = "\\~"
    let output = Replacer.replace(input)
    XCTAssertEqual(output, "~")
  }
  
  func testReplace_Caret() {
    let input = "\\^"
    let output = Replacer.replace(input)
    XCTAssertEqual(output, "^")
  }
  
  func testReplace_Backslash() {
    let input = "\\\\"
    let output = Replacer.replace(input)
    XCTAssertEqual(output, "\\")
  }
  
  func testReplace_All() {
    let input = "\\&\\%\\$\\#\\_\\{\\}\\~\\^\\\\"
    let output = Replacer.replace(input)
    XCTAssertEqual(output, "&%$#_{}~^\\")
  }
  
}

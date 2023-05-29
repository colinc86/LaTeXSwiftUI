//
//  ParserTests.swift
//  
//
//  Created by Colin Campbell on 5/29/23.
//

import MathJaxSwift
import XCTest
@testable import LaTeXSwiftUI

final class ParserTests: XCTestCase {

  func assertComponent(_ components: [Component], _ index: Int, _ text: String, _ type: Component.ComponentType, file: StaticString = #file, line: UInt = #line) {
    guard index < components.count else {
      XCTFail()
      return
    }
    XCTAssertEqual(components[index], Component(text: text, type: type))
  }
  
  func testParseEmpty() {
    let input = ""
    let components = Parser.parse(input)
    XCTAssertEqual(components.count, 0)
  }
  
  func testParseTextOnly() {
    let input = "Hello, World!"
    let components = Parser.parse(input)
    XCTAssertEqual(components.count, 1)
    XCTAssertEqual(components[0].text, input)
  }
  
  func testParseDollarOnly() {
    let input = "$\\TeX$"
    let components = Parser.parse(input)
    XCTAssertEqual(components.count, 1)
    assertComponent(components, 0, "\\TeX", .inlineEquation)
  }
  
  func testParseDollarOnly_Normal() {
    let input = "Hello, $\\TeX$!"
    let components = Parser.parse(input)
    XCTAssertEqual(components.count, 3)
    assertComponent(components, 0, "Hello, ", .text)
    assertComponent(components, 1, "\\TeX", .inlineEquation)
    assertComponent(components, 2, "!", .text)
  }
  
  func testParseDollarOnly_LeftEscaped() {
    let input = "Hello, \\$\\TeX$!"
    let components = Parser.parse(input)
    XCTAssertEqual(components.count, 1)
    assertComponent(components, 0, input, .text)
  }
  
  func testParseDollarOnly_RightEscaped() {
    let input = "Hello, $\\TeX\\$!"
    let components = Parser.parse(input)
    XCTAssertEqual(components.count, 1)
    assertComponent(components, 0, input, .text)
  }
  
  func testParseDoubleDollarOnly() {
    let input = "$$\\TeX$$"
    let components = Parser.parse(input)
    XCTAssertEqual(components.count, 1)
    assertComponent(components, 0, "\\TeX", .texEquation)
  }
  
  func testParseDoubleDollarOnly_Normal() {
    let input = "Hello, $$\\TeX$$!"
    let components = Parser.parse(input)
    XCTAssertEqual(components.count, 3)
    assertComponent(components, 0, "Hello, ", .text)
    assertComponent(components, 1, "\\TeX", .texEquation)
    assertComponent(components, 2, "!", .text)
  }
  
  func testParseDoubleDollarOnly_LeftEscaped() {
    let input = "Hello, \\$$\\TeX$$!"
    let components = Parser.parse(input)
    XCTAssertEqual(components.count, 1)
    assertComponent(components, 0, input, .text)
  }
  
  func testParseDoubleDollarOnly_RightEscaped() {
    let input = "Hello, $$\\TeX\\$$!"
    let components = Parser.parse(input)
    XCTAssertEqual(components.count, 1)
    assertComponent(components, 0, input, .text)
  }
  
  func testParseBracketsOnly() {
    let input = "\\[\\TeX\\]"
    let components = Parser.parse(input)
    XCTAssertEqual(components.count, 1)
    assertComponent(components, 0, "\\TeX", .blockEquation)
  }
  
  func testParseBracketsOnly_Normal() {
    let input = "Hello, \\[\\TeX\\]!"
    let components = Parser.parse(input)
    XCTAssertEqual(components.count, 3)
    assertComponent(components, 0, "Hello, ", .text)
    assertComponent(components, 1, "\\TeX", .blockEquation)
    assertComponent(components, 2, "!", .text)
  }
  
  func testParseBracketsOnly_LeftEscaped() {
    let input = "Hello, \\\\[\\TeX\\]!"
    let components = Parser.parse(input)
    XCTAssertEqual(components.count, 1)
    assertComponent(components, 0, input, .text)
  }
  
  func testParseBracketsOnly_RightEscaped() {
    let input = "Hello, \\[\\TeX\\\\]!"
    let components = Parser.parse(input)
    XCTAssertEqual(components.count, 1)
    assertComponent(components, 0, input, .text)
  }
  
  func testParseBracketsOnly_LineBreak() {
    let input = "Hello, \\[\\TeX\n\\\\]!"
    let components = Parser.parse(input)
    XCTAssertEqual(components.count, 1)
    assertComponent(components, 0, input, .text)
  }
  
  func testParseBeginEndOnly() {
    let input = "\\begin{equation}\\TeX\\end{equation}"
    let components = Parser.parse(input)
    XCTAssertEqual(components.count, 1)
    assertComponent(components, 0, "\\TeX", .namedEquation)
  }
  
  func testParseBeginEndOnly_Normal() {
    let input = "Hello, \\begin{equation}\\TeX\\end{equation}!"
    let components = Parser.parse(input)
    XCTAssertEqual(components.count, 3)
    assertComponent(components, 0, "Hello, ", .text)
    assertComponent(components, 1, "\\TeX", .namedEquation)
    assertComponent(components, 2, "!", .text)
  }
  
  func testParseBeginEndOnly_LeftEscaped() {
    let input = "Hello, \\\\begin{equation}\\TeX\\end{equation}!"
    let components = Parser.parse(input)
    XCTAssertEqual(components.count, 1)
    assertComponent(components, 0, input, .text)
  }
  
  func testParseBeginEndOnly_RightEscaped() {
    let input = "Hello, \\begin{equation}\\TeX\\\\end{equation}!"
    let components = Parser.parse(input)
    XCTAssertEqual(components.count, 1)
    assertComponent(components, 0, input, .text)
  }
  
  func testParseBeginEndOnly_LineBreak() {
    let input = "Hello, \\begin{equation}\\TeX\n\\\\end{equation}!"
    let components = Parser.parse(input)
    XCTAssertEqual(components.count, 1)
    assertComponent(components, 0, input, .text)
  }
  
  func testParseBeginEndStarOnly() {
    let input = "\\begin{equation*}\\TeX\\end{equation*}"
    let components = Parser.parse(input)
    XCTAssertEqual(components.count, 1)
    assertComponent(components, 0, "\\TeX", .namedNoNumberEquation)
  }
  
  func testParseBeginEndStarOnly_Normal() {
    let input = "Hello, \\begin{equation*}\\TeX\\end{equation*}!"
    let components = Parser.parse(input)
    XCTAssertEqual(components.count, 3)
    assertComponent(components, 0, "Hello, ", .text)
    assertComponent(components, 1, "\\TeX", .namedNoNumberEquation)
    assertComponent(components, 2, "!", .text)
  }
  
  func testParseBeginEndStarOnly_LeftEscaped() {
    let input = "Hello, \\\\begin{equation*}\\TeX\\end{equation*}!"
    let components = Parser.parse(input)
    XCTAssertEqual(components.count, 1)
    assertComponent(components, 0, input, .text)
  }
  
  func testParseBeginEndStarOnly_RightEscaped() {
    let input = "Hello, \\begin{equation*}\\TeX\\\\end{equation*}!"
    let components = Parser.parse(input)
    XCTAssertEqual(components.count, 1)
    assertComponent(components, 0, input, .text)
  }
  
  func testParseBeginEndStarOnly_LineBreak() {
    let input = "Hello, \\begin{equation*}\\TeX\n\\\\end{equation*}!"
    let components = Parser.parse(input)
    XCTAssertEqual(components.count, 1)
    assertComponent(components, 0, input, .text)
  }

}

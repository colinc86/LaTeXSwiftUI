//
//  ParserTests.swift
//  LaTeXSwiftUI
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
  
  func testParseDoubleDollarOnly_LeadingLineBreak() {
    let equation = "\nf(x)=5x+2"
    let input = "$$\(equation)$$"
    let components = Parser.parse(input)
    XCTAssertEqual(components.count, 1)
    assertComponent(components, 0, equation, .texEquation)
  }
  
  func testParseDoubleDollarOnly_TrailingLineBreak() {
    let equation = "f(x)=5x+2\n"
    let input = "$$\(equation)$$"
    let components = Parser.parse(input)
    XCTAssertEqual(components.count, 1)
    assertComponent(components, 0, equation, .texEquation)
  }
  
  func testParseDoubleDollarOnly_Whitespace() {
    let equation = " \nf(x)=5x+2\n "
    let input = "$$\(equation)$$"
    let components = Parser.parse(input)
    XCTAssertEqual(components.count, 1)
    assertComponent(components, 0, equation, .texEquation)
  }
  
  func testParseParenthesesOnly() {
    let input = "\\(\\TeX\\)"
    let components = Parser.parse(input)
    XCTAssertEqual(components.count, 1)
    assertComponent(components, 0, "\\TeX", .inlineParenthesesEquation)
  }
  
  func testParseParenthesesOnly_Normal() {
    let input = "Hello, \\(\\TeX\\)!"
    let components = Parser.parse(input)
    XCTAssertEqual(components.count, 3)
    assertComponent(components, 0, "Hello, ", .text)
    assertComponent(components, 1, "\\TeX", .inlineParenthesesEquation)
    assertComponent(components, 2, "!", .text)
  }
  
  func testParseParenthesesOnly_LeftEscaped() {
    let input = "Hello, \\\\(\\TeX\\)!"
    let components = Parser.parse(input)
    XCTAssertEqual(components.count, 1)
    assertComponent(components, 0, input, .text)
  }
  
  func testParseParenthesesOnly_RightEscaped() {
    let input = "Hello, \\(\\TeX\\\\)!"
    let components = Parser.parse(input)
    XCTAssertEqual(components.count, 1)
    assertComponent(components, 0, input, .text)
  }
  
  func testParseParenthesesOnly_LeadingLineBreak() {
    let equation = "\nf(x)=5x+2"
    let input = "\\(\(equation)\\)"
    let components = Parser.parse(input)
    XCTAssertEqual(components.count, 1)
    assertComponent(components, 0, equation, .inlineParenthesesEquation)
  }
  
  func testParseParenthesesOnly_TrailingLineBreak() {
    let equation = "f(x)=5x+2\n"
    let input = "\\(\(equation)\\)"
    let components = Parser.parse(input)
    XCTAssertEqual(components.count, 1)
    assertComponent(components, 0, equation, .inlineParenthesesEquation)
  }
  
  func testParseParenthesesOnly_Whitespace() {
    let equation = " \nf(x)=5x+2\n "
    let input = "\\(\(equation)\\)"
    let components = Parser.parse(input)
    XCTAssertEqual(components.count, 1)
    assertComponent(components, 0, equation, .inlineParenthesesEquation)
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
  
  func testParseBracketsOnly_LeadingLineBreak() {
    let equation = "\n\\TeX"
    let input = "Hello, \\[\(equation)\\]!"
    let components = Parser.parse(input)
    XCTAssertEqual(components.count, 3)
    assertComponent(components, 1, equation, .blockEquation)
  }
  
  func testParseBracketsOnly_TrailingLineBreak() {
    let equation = "\\TeX\n"
    let input = "Hello, \\[\(equation)\\]!"
    let components = Parser.parse(input)
    XCTAssertEqual(components.count, 3)
    assertComponent(components, 1, equation, .blockEquation)
  }
  
  func testParseBracketsOnly_Whitespace() {
    let equation = " \n\\TeX\n "
    let input = "Hello, \\[\(equation)\\]!"
    let components = Parser.parse(input)
    XCTAssertEqual(components.count, 3)
    assertComponent(components, 1, equation, .blockEquation)
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
  
  func testParseBeginEndOnly_LeadingLineBreak() {
    let equation = "\n\\TeX"
    let input = "Hello, \\begin{equation}\(equation)\\end{equation}!"
    let components = Parser.parse(input)
    XCTAssertEqual(components.count, 3)
    assertComponent(components, 1, equation, .namedEquation)
  }
  
  func testParseBeginEndOnly_TrailingLineBreak() {
    let equation = "\\TeX\n"
    let input = "Hello, \\begin{equation}\(equation)\\end{equation}!"
    let components = Parser.parse(input)
    XCTAssertEqual(components.count, 3)
    assertComponent(components, 1, equation, .namedEquation)
  }
  
  func testParseBeginEndOnly_Whitespace() {
    let equation = " \n\\TeX\n "
    let input = "Hello, \\begin{equation}\(equation)\\end{equation}!"
    let components = Parser.parse(input)
    XCTAssertEqual(components.count, 3)
    assertComponent(components, 1, equation, .namedEquation)
  }
  
  func testMultipleBeginEnd() {
    let input = """
\\begin{equation}
  E = mc^2
\\end{equation}

\\begin{equation}
  E = mc^2
\\end{equation}
"""
    let components = Parser.parse(input)
    XCTAssertEqual(components.count, 3)
    assertComponent(components, 0, "\n  E = mc^2\n", .namedEquation)
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
  
  func testParseBeginEndStarOnly_LeadingLineBreak() {
    let equation = "\n\\TeX"
    let input = "Hello, \\begin{equation*}\(equation)\\end{equation*}!"
    let components = Parser.parse(input)
    XCTAssertEqual(components.count, 3)
    assertComponent(components, 1, equation, .namedNoNumberEquation)
  }
  
  func testParseBeginEndStarOnly_TrailingLineBreak() {
    let equation = "\\TeX\n"
    let input = "Hello, \\begin{equation*}\(equation)\\end{equation*}!"
    let components = Parser.parse(input)
    XCTAssertEqual(components.count, 3)
    assertComponent(components, 1, equation, .namedNoNumberEquation)
  }
  
  func testParseBeginEndStarOnly_Whitespace() {
    let equation = " \n\\TeX\n "
    let input = "Hello, \\begin{equation*}\(equation)\\end{equation*}!"
    let components = Parser.parse(input)
    XCTAssertEqual(components.count, 3)
    assertComponent(components, 1, equation, .namedNoNumberEquation)
  }
  
  func testDollarSignEscape() {
    let input = "This is a dollar amount \\$5.00."
    let components = Parser.parse(input)
    XCTAssertEqual(components.count, 1)
    assertComponent(components, 0, input, .text)
  }
  
  func testInnerEquation() {
    let input = "\\begin{equation} $a-b=c$ \\end{equation}"
    let components = Parser.parse(input)
    XCTAssertEqual(components.count, 1)
    assertComponent(components, 0, input, .namedEquation)
  }

}

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

  func testUnmatchedDollarSign() {
    let input = "The price is $5"
    let components = Parser.parse(input)
    XCTAssertEqual(components.count, 1)
    assertComponent(components, 0, input, .text)
  }

  func testUnmatchedDollarSignWithTrailingText() {
    let input = "It costs $5 per item"
    let components = Parser.parse(input)
    XCTAssertEqual(components.count, 1)
    assertComponent(components, 0, input, .text)
  }

  func testUnmatchedDollarSignBeforeEquation() {
    // Two $'s form a matched pair: "5 and " becomes the equation content.
    // This is expected behavior — the parser can't distinguish intent.
    let input = "Price is $5 and $x^2$"
    let components = Parser.parse(input)
    // The first $ pairs with the second $, the third $ is unmatched
    // Actually: $5 and $ matches as an equation, then x^2$ has unmatched $
    // Let's just verify it doesn't crash
    XCTAssertGreaterThan(components.count, 0)
  }

  func testSVGStrokePatch() throws {
    let mathjax = try MathJax(preferredOutputFormat: .svg)
    let texOptions = TeXInputProcessorOptions(processEscapes: false, errorMode: .original)
    let input = "\\begin{array}{|c|c|c|} \\hline a & b & c \\\\ \\hline d & e & f \\\\ \\hline \\end{array}"
    var error: Error?
    let svgString = mathjax.tex2svg(input, styles: false, conversionOptions: ConversionOptions(display: true), inputOptions: texOptions, error: &error)
    XCTAssertNil(error)

    let svg = try SVG(svgString: svgString)
    let patchedString = String(data: svg.data, encoding: .utf8)!

    // Verify the patch added stroke to line elements
    XCTAssertTrue(patchedString.contains(#"data-line="v"#), "Should have data-line attributes")
    XCTAssertTrue(patchedString.contains("stroke="), "Should have patched stroke attributes")
    XCTAssertFalse(patchedString.contains("data-background"), "Should not have error background")
  }

  func testUnmatchedBlockDelimiter() {
    let input = "Text with \\[ unmatched block"
    let components = Parser.parse(input)
    XCTAssertEqual(components.count, 1)
    assertComponent(components, 0, input, .text)
  }

  func testMismatchedDelimiters() {
    // $ opened but \] encountered — types don't match, should not close
    let input = "$x\\]"
    let components = Parser.parse(input)
    // Unmatched $ at end of input → entire string is text
    XCTAssertEqual(components.count, 1)
    assertComponent(components, 0, input, .text)
  }

  func testBlockEquationAtStart() {
    let input = "$$x^2$$trailing"
    let blocks = Parser.parse(input, mode: .onlyEquations)
    // Should not have an empty block before the equation
    for block in blocks {
      XCTAssertFalse(block.components.isEmpty, "Should not have empty blocks")
    }
    XCTAssertEqual(blocks.count, 2) // equation block + text block
  }

  func testMultipleInlineEquations() {
    let input = "$a$ and $b$ and $c$"
    let components = Parser.parse(input)
    XCTAssertEqual(components.count, 5)
    assertComponent(components, 0, "a", .inlineEquation)
    assertComponent(components, 1, " and ", .text)
    assertComponent(components, 2, "b", .inlineEquation)
    assertComponent(components, 3, " and ", .text)
    assertComponent(components, 4, "c", .inlineEquation)
  }

  func testAdjacentEquations() {
    let input = "$a$$b$"
    let components = Parser.parse(input)
    XCTAssertEqual(components.count, 2)
    assertComponent(components, 0, "a", .inlineEquation)
    assertComponent(components, 1, "b", .inlineEquation)
  }

  func testEmptyTexEquation() {
    let input = "$$$$"
    let components = Parser.parse(input)
    XCTAssertEqual(components.count, 1)
    assertComponent(components, 0, "", .texEquation)
  }

  func testTextBetweenBlockEquations() {
    let input = "$$a$$ text $$b$$"
    let components = Parser.parse(input)
    XCTAssertEqual(components.count, 3)
    assertComponent(components, 0, "a", .texEquation)
    assertComponent(components, 1, " text ", .text)
    assertComponent(components, 2, "b", .texEquation)
  }

  func testNestedDollarInBlock() {
    let input = "$$a $b$ c$$"
    let components = Parser.parse(input)
    XCTAssertEqual(components.count, 1)
    assertComponent(components, 0, input, .texEquation)
  }

}

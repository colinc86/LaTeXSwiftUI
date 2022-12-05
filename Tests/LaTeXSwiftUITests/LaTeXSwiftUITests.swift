import XCTest
@testable import LaTeXSwiftUI

@available(iOS 16.1, *)
final class LaTeXSwiftUITests: XCTestCase {
  
  func assertComponent(_ component: Component, _ text: String, _ type: Component.ComponentType, file: StaticString = #file, line: UInt = #line) {
    XCTAssertEqual(component, Component(text: text, type: type))
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
    assertComponent(components[0], "\\TeX", .inlineEquation)
  }
  
  func testParseDollarOnly_Normal() {
    let input = "Hello, $\\TeX$!"
    let components = Parser.parse(input)
    XCTAssertEqual(components.count, 3)
    assertComponent(components[0], "Hello, ", .text)
    assertComponent(components[1], "\\TeX", .inlineEquation)
    assertComponent(components[2], "!", .text)
  }
  
  func testParseDollarOnly_LeftEscaped() {
    let input = "Hello, \\$\\TeX$!"
    let components = Parser.parse(input)
    XCTAssertEqual(components.count, 1)
    assertComponent(components[0], input, .text)
  }
  
  func testParseDollarOnly_RightEscaped() {
    let input = "Hello, $\\TeX\\$!"
    let components = Parser.parse(input)
    XCTAssertEqual(components.count, 1)
    assertComponent(components[0], input, .text)
  }
  
  func testParseDoubleDollarOnly() {
    let input = "$$\\TeX$$"
    let components = Parser.parse(input)
    print(components)
    XCTAssertEqual(components.count, 1)
    assertComponent(components[0], "\\TeX", .texBlockEquation)
  }
  
  func testParseDoubleDollarOnly_Normal() {
    let input = "Hello, $$\\TeX$$!"
    let components = Parser.parse(input)
    XCTAssertEqual(components.count, 3)
    assertComponent(components[0], "Hello, ", .text)
    assertComponent(components[1], "\\TeX", .texBlockEquation)
    assertComponent(components[2], "!", .text)
  }
  
  func testParseDoubleDollarOnly_LeftEscaped() {
    let input = "Hello, \\$$\\TeX$$!"
    let components = Parser.parse(input)
    XCTAssertEqual(components.count, 1)
    assertComponent(components[0], input, .text)
  }
  
  func testParseDoubleDollarOnly_RightEscaped() {
    let input = "Hello, $$\\TeX\\$$!"
    let components = Parser.parse(input)
    XCTAssertEqual(components.count, 1)
    assertComponent(components[0], input, .text)
  }
  
  func testParseBracketsOnly_LeftEscaped() {
    let input = "Hello, \\\\[\\TeX\\]!"
    let components = Parser.parse(input)
    XCTAssertEqual(components.count, 1)
    assertComponent(components[0], input, .text)
  }
  
  func testParseBracketsOnly_RightEscaped() {
    let input = "Hello, \\[\\TeX\\\\]!"
    let components = Parser.parse(input)
    XCTAssertEqual(components.count, 1)
    assertComponent(components[0], input, .text)
  }
  
  func testParseBracketsOnly_LineBreak() {
    let input = "Hello, \\[\\TeX\n\\\\]!"
    let components = Parser.parse(input)
    XCTAssertEqual(components.count, 1)
    assertComponent(components[0], input, .text)
  }
  
  func testParseBeginEndOnly() {
    let input = "\\begin{equation}\\TeX\\end{equation}"
    let components = Parser.parse(input)
    XCTAssertEqual(components.count, 1)
    assertComponent(components[0], "\\TeX", .namedEquation)
  }
  
  func testParseBeginEndOnly_Normal() {
    let input = "Hello, \\begin{equation}\\TeX\\end{equation}!"
    let components = Parser.parse(input)
    XCTAssertEqual(components.count, 3)
    assertComponent(components[0], "Hello, ", .text)
    assertComponent(components[1], "\\TeX", .namedEquation)
    assertComponent(components[2], "!", .text)
  }
  
  func testParseBeginEndOnly_LeftEscaped() {
    let input = "Hello, \\\\begin{equation}\\TeX\\end{equation}!"
    let components = Parser.parse(input)
    XCTAssertEqual(components.count, 1)
    assertComponent(components[0], input, .text)
  }
  
  func testParseBeginEndOnly_RightEscaped() {
    let input = "Hello, \\begin{equation}\\TeX\\\\end{equation}!"
    let components = Parser.parse(input)
    XCTAssertEqual(components.count, 1)
    assertComponent(components[0], input, .text)
  }
  
  func testParseBeginEndOnly_LineBreak() {
    let input = "Hello, \\begin{equation}\\TeX\n\\\\end{equation}!"
    let components = Parser.parse(input)
    XCTAssertEqual(components.count, 1)
    assertComponent(components[0], input, .text)
  }
  
  func testSVGGeometry_parseAlignment() {
    let input = "\"vertical-align: -1.602ex;\""
    let value = SVGGeometry.parseAlignment(from: input)
    XCTAssertEqual(value, -1.602)
  }
  
  func testSVGGeometry_parseAlignmentZero() {
    let input = "\"vertical-align: 0;\""
    let value = SVGGeometry.parseAlignment(from: input)
    XCTAssertEqual(value, 0)
  }
  
  func testSVGGeometry_parseXHeight() {
    let input = "\"-1.602ex\""
    let value = SVGGeometry.parseXHeight(from: input)
    XCTAssertEqual(value, -1.602)
  }
  
  func testSVGGeometry_parseViewBox() {
    let input = "\"0 -1342 940 2050\""
    let value = SVGGeometry.parseViewBox(from: input)
    XCTAssertEqual(value, CGRect(x: 0, y: -1342, width: 940, height: 2050))
  }
  
  func testSVGGeometry() throws {
    let input = """
<svg style="vertical-align: -1.602ex;" xmlns="http://www.w3.org/2000/svg" width="2.127ex" height="4.638ex" role="img" focusable="false" viewBox="0 -1342 940 2050" xmlns:xlink="http://www.w3.org/1999/xlink"><defs><path id="MJX-1-MM-N-32" d="M449 174L424 174C419 144 412 100 402 85C395 77 329 77 307 77L127 77L233 180C389 318 449 372 449 472C449 586 359 666 237 666C124 666 50 574 50 485C50 429 100 429 103 429C120 429 155 441 155 482C155 508 137 534 102 534C94 534 92 534 89 533C112 598 166 635 224 635C315 635 358 554 358 472C358 392 308 313 253 251L61 37C50 26 50 24 50 0L421 0Z"></path><path id="MJX-1-MM-N-33" d="M457 171C457 253 394 331 290 352C372 379 430 449 430 528C430 610 342 666 246 666C145 666 69 606 69 530C69 497 91 478 120 478C151 478 171 500 171 529C171 579 124 579 109 579C140 628 206 641 242 641C283 641 338 619 338 529C338 517 336 459 310 415C280 367 246 364 221 363C213 362 189 360 182 360C174 359 167 358 167 348C167 337 174 337 191 337L235 337C317 337 354 269 354 171C354 35 285 6 241 6C198 6 123 23 88 82C123 77 154 99 154 137C154 173 127 193 98 193C74 193 42 179 42 135C42 44 135-22 244-22C366-22 457 69 457 171Z"></path></defs><g stroke="currentColor" fill="currentColor" stroke-width="0" transform="scale(1,-1)"><g data-mml-node="math"><g data-mml-node="mfrac"><g data-mml-node="mn" transform="translate(220,676)"><use data-c="32" xlink:href="#MJX-1-MM-N-32"></use></g><g data-mml-node="mn" transform="translate(220,-686)"><use data-c="33" xlink:href="#MJX-1-MM-N-33"></use></g><rect width="700" height="60" x="120" y="220"></rect></g></g></g></svg>
"""
    let geometry = try SVGGeometry(svg: input)
    XCTAssertNoThrow(geometry)
    XCTAssertEqual(geometry.verticalAlignment, -1.602)
    XCTAssertEqual(geometry.width, 2.127)
    XCTAssertEqual(geometry.height, 4.638)
    XCTAssertEqual(geometry.frame, CGRect(x: 0, y: -1342, width: 940, height: 2050))
  }
  
}

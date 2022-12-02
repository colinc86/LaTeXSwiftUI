import XCTest
@testable import LaTeXSwiftUI

final class LaTeXSwiftUITests: XCTestCase {
  
  func assertComponent(_ component: LaTeXEquationParser.LaTeXComponent, _ text: String, _ type: LaTeXEquationParser.LaTeXComponent.ComponentType, file: StaticString = #file, line: UInt = #line) {
    XCTAssertEqual(component, LaTeXEquationParser.LaTeXComponent(text: text, type: type))
  }
  
  func testParseEmpty() {
    let input = ""
    let components = LaTeXEquationParser.parse(input)
    XCTAssertEqual(components.count, 0)
  }
  
  func testParseTextOnly() {
    let input = "Hello, World!"
    let components = LaTeXEquationParser.parse(input)
    XCTAssertEqual(components.count, 1)
    XCTAssertEqual(components[0].text, input)
  }
  
  func testParseDollarOnly() {
    let input = "$\\TeX$"
    let components = LaTeXEquationParser.parse(input)
    XCTAssertEqual(components.count, 1)
    assertComponent(components[0], "\\TeX", .inlineEquation)
  }
  
  func testParseDollarOnly_Normal() {
    let input = "Hello, $\\TeX$!"
    let components = LaTeXEquationParser.parse(input)
    XCTAssertEqual(components.count, 3)
    assertComponent(components[0], "Hello, ", .text)
    assertComponent(components[1], "\\TeX", .inlineEquation)
    assertComponent(components[2], "!", .text)
  }
  
  func testParseDollarOnly_LeftEscaped() {
    let input = "Hello, \\$\\TeX$!"
    let components = LaTeXEquationParser.parse(input)
    XCTAssertEqual(components.count, 1)
    assertComponent(components[0], input, .text)
  }
  
  func testParseDollarOnly_RightEscaped() {
    let input = "Hello, $\\TeX\\$!"
    let components = LaTeXEquationParser.parse(input)
    XCTAssertEqual(components.count, 1)
    assertComponent(components[0], input, .text)
  }
  
  func testParseBracketsOnly() {
    let input = "\\[\\TeX\\]"
    let components = LaTeXEquationParser.parse(input)
    XCTAssertEqual(components.count, 1)
    assertComponent(components[0], "\\TeX", .multilineEquation)
  }
  
  func testParseBracketsOnly_Normal() {
    let input = "Hello, \\[\\TeX\\]!"
    let components = LaTeXEquationParser.parse(input)
    XCTAssertEqual(components.count, 3)
    assertComponent(components[0], "Hello, ", .text)
    assertComponent(components[1], "\\TeX", .multilineEquation)
    assertComponent(components[2], "!", .text)
  }
  
  func testParseBracketsOnly_LeftEscaped() {
    let input = "Hello, \\\\[\\TeX\\]!"
    let components = LaTeXEquationParser.parse(input)
    XCTAssertEqual(components.count, 1)
    assertComponent(components[0], input, .text)
  }
  
  func testParseBracketsOnly_RightEscaped() {
    let input = "Hello, \\[\\TeX\\\\]!"
    let components = LaTeXEquationParser.parse(input)
    XCTAssertEqual(components.count, 1)
    assertComponent(components[0], input, .text)
  }
  
  func testParseBracketsOnly_LineBreak() {
    let input = "Hello, \\[\\TeX\n\\\\]!"
    let components = LaTeXEquationParser.parse(input)
    XCTAssertEqual(components.count, 1)
    assertComponent(components[0], input, .text)
  }
  
  func testParseBeginEndOnly() {
    let input = "\\begin{equation}\\TeX\\end{equation}"
    let components = LaTeXEquationParser.parse(input)
    XCTAssertEqual(components.count, 1)
    assertComponent(components[0], "\\TeX", .namedEquation)
  }
  
  func testParseBeginEndOnly_Normal() {
    let input = "Hello, \\begin{equation}\\TeX\\end{equation}!"
    let components = LaTeXEquationParser.parse(input)
    XCTAssertEqual(components.count, 3)
    assertComponent(components[0], "Hello, ", .text)
    assertComponent(components[1], "\\TeX", .namedEquation)
    assertComponent(components[2], "!", .text)
  }
  
  func testParseBeginEndOnly_LeftEscaped() {
    let input = "Hello, \\\\begin{equation}\\TeX\\end{equation}!"
    let components = LaTeXEquationParser.parse(input)
    XCTAssertEqual(components.count, 1)
    assertComponent(components[0], input, .text)
  }
  
  func testParseBeginEndOnly_RightEscaped() {
    let input = "Hello, \\begin{equation}\\TeX\\\\end{equation}!"
    let components = LaTeXEquationParser.parse(input)
    XCTAssertEqual(components.count, 1)
    assertComponent(components[0], input, .text)
  }
  
  func testParseBeginEndOnly_LineBreak() {
    let input = "Hello, \\begin{equation}\\TeX\n\\\\end{equation}!"
    let components = LaTeXEquationParser.parse(input)
    XCTAssertEqual(components.count, 1)
    assertComponent(components[0], input, .text)
  }
  
  func testMultiple_MutuallyExclusive() {
    let input = "Hello, $\\TeX$ equations! \\[x^2\\]"
    let components = LaTeXEquationParser.parse(input)
    XCTAssertEqual(components.count, 4)
    assertComponent(components[0], "Hello, ", .text)
    assertComponent(components[1], "\\TeX", .inlineEquation)
    assertComponent(components[2], " equations! ", .text)
    assertComponent(components[3], "x^2", .multilineEquation)
  }
  
  func testMultiple_MutuallyInclusive() {
    let input = "Hello\\[, $\\TeX$ equations! x^2\\]"
    let components = LaTeXEquationParser.parse(input)
    XCTAssertEqual(components.count, 2)
    assertComponent(components[0], "Hello", .text)
    assertComponent(components[1], ", $\\TeX$ equations! x^2", .multilineEquation)
  }
  
}

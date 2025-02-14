//
//  SVGGeometry.swift
//  LaTeXSwiftUI
//
//  Copyright (c) 2023 Colin Campbell
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to
//  deal in the Software without restriction, including without limitation the
//  rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
//  IN THE SOFTWARE.
//

import Foundation
import SwiftUI

/// The geometry of a SVG.
internal struct SVGGeometry: Codable, Hashable {

  // MARK: Types

  /// A unit of height that defines the height of the `x` character
  /// of a font.
  typealias XHeight = CGFloat

  /// A parsing error.
  enum ParsingError: Error {
    case missingSVGElement
    case missingGeometry
  }

  // MARK: Static properties

  /// The SVG element regex.
  private static let svgRegex: NSRegularExpression = {
    try! NSRegularExpression(pattern: "<svg.*?>", options: [])
  }()

  /// The attribute regex.
  private static let attributeRegex: NSRegularExpression = {
    try! NSRegularExpression(pattern: "\\w*:*\\w+=\".*?\"", options: [])
  }()

  // MARK: Public properties

  /// The SVG's vertical alignment (offset).
  let verticalAlignment: XHeight

  /// The SVG's width.
  let width: XHeight

  /// The SVG's height.
  let height: XHeight

  /// The SVG's frame.
  let frame: CGRect

  // MARK: Initializers

  /// Initializes a geometry from an SVG.
  ///
  /// - Parameter svg: The SVG.
  init(svg: String) throws {
    // Find the SVG element
    let range = NSRange(location: 0, length: svg.utf16.count)
    guard let match = SVGGeometry.svgRegex.firstMatch(in: svg, options: [], range: range) else {
      throw ParsingError.missingSVGElement
    }

    // Get the SVG element
    guard let matchRange = Range(match.range, in: svg) else {
      throw ParsingError.missingSVGElement
    }
    let svgElement = String(
      svg[svg.index(after: matchRange.lowerBound)..<svg.index(before: matchRange.upperBound)])

    // Get its attributes
    var verticalAlignment: XHeight?
    var width: XHeight?
    var height: XHeight?
    var frame: CGRect?

    let attrRange = NSRange(location: 0, length: svgElement.utf16.count)
    SVGGeometry.attributeRegex.enumerateMatches(in: svgElement, options: [], range: attrRange) {
      match, _, _ in
      guard let match = match,
        let matchRange = Range(match.range, in: svgElement)
      else { return }

      let attribute = String(svgElement[matchRange])
      let components = attribute.components(separatedBy: CharacterSet(charactersIn: "="))
      guard components.count == 2 else {
        return
      }
      switch components[0] {
      case "style": verticalAlignment = SVGGeometry.parseAlignment(from: components[1])
      case "width": width = SVGGeometry.parseXHeight(from: components[1])
      case "height": height = SVGGeometry.parseXHeight(from: components[1])
      case "viewBox": frame = SVGGeometry.parseViewBox(from: components[1])
      default: return
      }
    }

    guard let verticalAlignment = verticalAlignment,
      let width = width,
      let height = height,
      let frame = frame
    else {
      throw ParsingError.missingGeometry
    }

    self.verticalAlignment = verticalAlignment
    self.width = width
    self.height = height
    self.frame = frame
  }

}

// MARK: Static methods

extension SVGGeometry {

  /// Parses the alignment from the style attribute.
  ///
  /// "vertical-align: -1.602ex;"
  ///
  /// - Parameter string: The input string.
  /// - Returns: The alignment's x-height.
  static func parseAlignment(from string: String) -> XHeight? {
    let trimmed = string.trimmingCharacters(in: CharacterSet(charactersIn: "\";"))
    let components = trimmed.components(separatedBy: CharacterSet(charactersIn: ":"))
    guard components.count == 2 else { return nil }
    let value = components[1].trimmingCharacters(in: .whitespaces)
    return XHeight(stringValue: value)
  }

  /// Parses the x-height value from an attribute.
  ///
  /// "2.127ex"
  ///
  /// - Parameter string: The input string.
  /// - Returns: The x-height.
  static func parseXHeight(from string: String) -> XHeight? {
    let trimmed = string.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
    return XHeight(stringValue: trimmed)
  }

  /// Parses the view-box from an attribute.
  ///
  /// "0 -1342 940 2050"
  ///
  /// - Parameter string: The input string.
  /// - Returns: The view-box.
  static func parseViewBox(from string: String) -> CGRect? {
    let trimmed = string.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
    let components = trimmed.components(separatedBy: CharacterSet.whitespaces)
    guard components.count == 4 else { return nil }
    guard let x = Double(components[0]),
      let y = Double(components[1]),
      let width = Double(components[2]),
      let height = Double(components[3])
    else {
      return nil
    }
    return CGRect(x: x, y: y, width: width, height: height)
  }

}

extension SVGGeometry.XHeight {

  /// Initializes a x-height value.
  ///
  /// "2.127ex"
  ///
  /// - Parameter stringValue: The x-height.
  init?(stringValue: String) {
    let trimmed = stringValue.trimmingCharacters(in: CharacterSet(charactersIn: "ex"))
    if let value = Double(trimmed) {
      self = CGFloat(value)
    } else {
      return nil
    }
  }

  /// Converts the x-height to points.
  ///
  /// - Parameter xHeight: The height of 1 x-height unit.
  /// - Returns: The points.
  func toPoints(_ xHeight: CGFloat) -> CGFloat {
    xHeight * self
  }

  /// Converts the x-height to points.
  ///
  /// - Parameter font: The font.
  /// - Returns: The points.
  func toPoints(_ font: _Font) -> CGFloat {
    toPoints(font.xHeight)
  }

  /// Converts the x-height to points.
  ///
  /// - Parameter font: The font.
  /// - Returns: The points.
  func toPoints(_ font: Font) -> CGFloat {
    #if os(iOS)
      toPoints(_Font.preferredFont(from: font))
    #else
      toPoints(_Font.preferredFont(from: font))
    #endif
  }

}

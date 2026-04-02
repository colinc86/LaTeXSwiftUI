//
//  SVG.swift
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

/// Contains SVG information.
internal struct SVG: Codable, Hashable, Sendable {
  
  /// An error produced when creating an SVG.
  enum SVGError: Error, Sendable {
    case encodingSVGData
  }
  
  /// The SVG's data.
  let data: Data
  
  /// The SVG's geometry.
  let geometry: SVGGeometry
  
  /// Any error text produced when creating the SVG.
  let errorText: String?
  
  // MARK: Initializers
  
  /// Initializes a new SVG from data.
  ///
  /// - Parameter data: The SVG data.
  init(data: Data) throws {
    self = try JSONDecoder().decode(Self.self, from: data)
  }
  
  /// Initializes a new SVG.
  ///
  /// - Parameters:
  ///   - svgString: The SVG's input string.
  ///   - errorText: The error text that was generated when creating the SVG.
  init(svgString: String, errorText: String? = nil) throws {
    self.errorText = errorText

    // Patch SVG elements that rely on CSS for stroke styling.
    // SwiftDraw doesn't apply CSS stylesheets, so we inline the
    // stroke attributes that MathJax's CSS would normally provide
    // for array borders and horizontal rules.
    let patchedSVG = Self.patchStrokeAttributes(svgString)

    // Get the SVG's geometry
    geometry = try SVGGeometry(svg: patchedSVG)

    // Get the SVG data
    if let svgData = patchedSVG.data(using: .utf8) {
      data = svgData
    }
    else {
      throw SVGError.encodingSVGData
    }
  }
  
}

// MARK: Methods

extension SVG {
  
  /// The JSON encoded value of the receiver.
  ///
  /// - Returns: The receivers JSON encoded data.
  func encoded() throws -> Data {
    try JSONEncoder().encode(self)
  }
  
  /// Patches SVG elements that rely on MathJax CSS for stroke styling.
  ///
  /// MathJax renders array borders and horizontal rules using `<line>` and
  /// `<rect>` elements with `data-frame` or `data-line` attributes. These
  /// elements depend on a CSS rule for their appearance:
  ///
  ///     [data-frame],[data-line]{stroke-width:70px;fill:none}
  ///
  /// SwiftDraw does not apply CSS stylesheets, so these elements render
  /// invisibly. This method inlines the stroke attributes directly onto
  /// the affected elements.
  ///
  /// - Parameter svgString: The raw SVG string from MathJax.
  /// - Returns: The patched SVG string.
  private static func patchStrokeAttributes(_ svgString: String) -> String {
    // MathJax uses <line> for array column separators and horizontal
    // rules, and <rect data-frame> for outer table borders. These
    // elements rely on parent <g> inheritance or CSS for stroke color,
    // but SwiftDraw doesn't support either. We inline the stroke
    // attribute on these elements so they render correctly.
    var result = svgString

    // Patch <line> elements that have data-line (internal separators
    // and horizontal rules). These have neither stroke nor stroke-width.
    // MathJax's CSS uses 70 SVG units for their stroke width.
    if let dataLineRegex = try? NSRegularExpression(
      pattern: #"(<line\b[^>]*\bdata-line\b[^>]*?)(\/?>)"#) {
      let mutable = NSMutableString(string: result)
      dataLineRegex.replaceMatches(
        in: mutable, options: [],
        range: NSRange(location: 0, length: mutable.length),
        withTemplate: ##"$1 stroke="#000" stroke-width="70" $2"##)
      result = mutable as String
    }

    // Patch <line> elements that have stroke-width but no stroke color
    // (outer border lines). These already have the correct width.
    if let borderLineRegex = try? NSRegularExpression(
      pattern: #"(<line\b(?![^>]*\bdata-line\b)(?![^>]*\bstroke=")[^>]*?\bstroke-width="[^"]*"[^>]*?)(\/?>)"#) {
      let mutable = NSMutableString(string: result)
      borderLineRegex.replaceMatches(
        in: mutable, options: [],
        range: NSRange(location: 0, length: mutable.length),
        withTemplate: ##"$1 stroke="#000" $2"##)
      result = mutable as String
    }

    // Patch <rect> elements with data-frame (outer table borders).
    // These need stroke, stroke-width, and fill="none" to render as
    // borders. We don't patch other <rect> elements because MathJax
    // uses those for filled regions (fraction bars, etc.).
    if let rectRegex = try? NSRegularExpression(
      pattern: #"(<rect\b[^>]*\bdata-frame\b(?![^>]*\bstroke=")[^>]*?)(\/?>)"#) {
      let mutable = NSMutableString(string: result)
      rectRegex.replaceMatches(
        in: mutable, options: [],
        range: NSRange(location: 0, length: mutable.length),
        withTemplate: ##"$1 stroke="#000" stroke-width="70" fill="none" $2"##)
      result = mutable as String
    }

    return result
  }

  /// The size of the SVG based on the current font's x-height.
  ///
  /// - Parameter xHeight: The font's x-height.
  /// - Returns: A size.
  func size(for xHeight: CGFloat) -> CGSize {
    CGSize(
      width: geometry.width.toPoints(xHeight),
      height: geometry.height.toPoints(xHeight)
    )
  }
  
}

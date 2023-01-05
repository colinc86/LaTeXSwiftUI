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
internal struct SVG: Codable, Hashable {
  
  /// An error produced when creating an SVG.
  enum SVGError: Error {
    case encodingSVGData
  }
  
  /// The SVG's data.
  let data: Data
  
  /// The SVG's geometry.
  let geometry: SVGGeometry
  
  /// Any error text produced when creating the SVG.
  let errorText: String?
  
  // MARK: Initializers
  
  /// Initializes a new SVG.
  ///
  /// - Parameters:
  ///   - svgString: The SVG's input string.
  ///   - errorText: The error text that was generated when creating the SVG.
  init(svgString: String, errorText: String? = nil) throws {
    self.errorText = errorText
    
    // Get the SVG's geometry
    geometry = try SVGGeometry(svg: svgString)
    
    // Get the SVG data
    if let svgData = svgString.data(using: .utf8) {
      data = svgData
    }
    else {
      throw SVGError.encodingSVGData
    }
  }
  
}

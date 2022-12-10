//
//  SVG.swift
//  LaTeXSwiftUI
//
//  Created by Colin Campbell on 12/9/22.
//

import Foundation

/// Contains SVG information.
internal struct SVG: Hashable {
  
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

//
//  SVG.swift
//  LaTeXSwiftUI
//
//  Created by Colin Campbell on 12/9/22.
//

import Foundation

/// Contains SVG information.
internal struct SVG: Hashable {
  
  enum SVGError: Error {
    case encodingSVGData
  }
  
  let data: Data
  let geometry: SVGGeometry
  let errorText: String?
  
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

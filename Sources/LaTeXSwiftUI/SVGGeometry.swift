//
//  SVGGeometry.swift
//  LaTeXSwiftUI
//
//  Created by Colin Campbell on 12/3/22.
//

import Foundation
import SwiftUI

internal struct SVGGeometry {
  
  typealias XHeight = CGFloat
  
  enum ParsingError: Error {
    case missingSVGElement
    case missingGeometry
  }
  
  static let svgRegex = #/<svg.*?>/#
  static let attributeRegex = #/\w*:*\w+=".*?"/#
  
  let verticalAlignment: XHeight
  let width: XHeight
  let height: XHeight
  let frame: CGRect
  
  init(verticalAlignment: XHeight, width: XHeight, height: XHeight, frame: CGRect) {
    self.verticalAlignment = verticalAlignment
    self.width = width
    self.height = height
    self.frame = frame
  }
  
  init(svg: String) throws {
    // Find the SVG element
    guard let match = svg.firstMatch(of: SVGGeometry.svgRegex) else {
      throw ParsingError.missingSVGElement
    }
    
    // Get the SVG element
    let svgElement = String(svg[svg.index(after: match.range.lowerBound) ..< svg.index(before: match.range.upperBound)])
    
    // Get its attributes
    var verticalAlignment: XHeight?
    var width: XHeight?
    var height: XHeight?
    var frame: CGRect?
    
    for match in svgElement.matches(of: SVGGeometry.attributeRegex) {
      let attribute = String(svgElement[match.range])
      let components = attribute.components(separatedBy: CharacterSet(charactersIn: "="))
      guard components.count == 2 else {
        continue
      }
      switch components[0] {
      case "style": verticalAlignment = SVGGeometry.parseAlignment(from: components[1])
      case "width": width = SVGGeometry.parseXHeight(from: components[1])
      case "height": height = SVGGeometry.parseXHeight(from: components[1])
      case "viewBox": frame = SVGGeometry.parseViewBox(from: components[1])
      default: continue
      }
    }
    
    guard let verticalAlignment = verticalAlignment,
          let width = width,
          let height = height,
          let frame = frame else {
      throw ParsingError.missingGeometry
    }
    
    self.init(
      verticalAlignment: verticalAlignment,
      width: width,
      height: height,
      frame: frame)
  }
  
  static func parseAlignment(from string: String) -> XHeight? {
    //"vertical-align: -1.602ex;"
    let trimmed = string.trimmingCharacters(in: CharacterSet(charactersIn: "\";"))
    let components = trimmed.components(separatedBy: CharacterSet(charactersIn: ":"))
    guard components.count == 2 else { return nil }
    let value = components[1].trimmingCharacters(in: .whitespaces)
    return XHeight(stringValue: value)
  }
  
  static func parseXHeight(from string: String) -> XHeight? {
    // "2.127ex"
    let trimmed = string.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
    return XHeight(stringValue: trimmed)
  }
  
  static func parseViewBox(from string: String) -> CGRect? {
    // "0 -1342 940 2050"
    let trimmed = string.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
    let components = trimmed.components(separatedBy: CharacterSet.whitespaces)
    guard components.count == 4 else { return nil }
    guard let x = Double(components[0]),
          let y = Double(components[1]),
          let width = Double(components[2]),
          let height = Double(components[3]) else {
      return nil
    }
    return CGRect(x: x, y: y, width: width, height: height)
  }
  
}

extension SVGGeometry.XHeight {
  
  init?(stringValue: String) {
    guard stringValue.hasSuffix("ex") else { return nil }
    let trimmed = stringValue.trimmingCharacters(in: CharacterSet(charactersIn: "ex"))
    if let value = Double(trimmed) {
      self = CGFloat(value)
    }
    else {
      return nil
    }
  }
  
  func toPoints(_ xHeight: CGFloat) -> CGFloat {
    xHeight * self
  }
  
  func toPoints(_ font: _Font) -> CGFloat {
    toPoints(font.xHeight)
  }
  
  func toPoints(_ font: Font) -> CGFloat {
    #if os(iOS)
    toPoints(_Font.preferredFont(from: font))
    #else
    toPoints(_Font.preferredFont(from: font))
    #endif
  }
  
}



//
//  LaTeXRenderer.swift
//  LaTeXSwiftUI
//
//  Created by Colin Campbell on 12/3/22.
//

import Foundation
import MathJaxSwift
import SVGView
import SwiftUI

#if os(iOS)
import UIKit
#else
import Cocoa
#endif

internal class Renderer {
  
  /// The shared renderer.
  static let shared = Renderer()
  
  /// The MathJax instance.
  private let mathjax: MathJax?
  
  init() {
    do {
      mathjax = try MathJax(preferredOutputFormat: .svg)
    }
    catch {
      NSLog("Error initializing MathJax: \(error)")
      mathjax = nil
    }
  }
  
  /// Called when the math components should be (re)rendered.
  func render(_ components: [Component], xHeight: CGFloat, displayScale: CGFloat, textColor: Color) async throws -> [Component] {
    let cgColor = _Color(textColor).cgColor
    guard let colorComponents = cgColor.components, colorComponents.count >= 3 else {
      return components
    }
    
    let red: CGFloat = colorComponents[0]
    let green: CGFloat = colorComponents[1]
    let blue: CGFloat = colorComponents[2]
    
    var newComponents = [Component]()
    for component in components {
      guard component.type.isEquation else {
        newComponents.append(component)
        continue
      }

      let colorComponent = "\\definecolor{custom}{rgb}{\(red), \(green), \(blue)} \\color{custom} \(component.text)"
      guard let svgString = try await mathjax?.tex2svg(colorComponent, inline: component.type.inline) else {
        newComponents.append(component)
        continue
      }
      
      // Parse the size and offset
      let geometry = try SVGGeometry(svg: svgString)
      let offset = geometry.verticalAlignment.toPoints(xHeight)

      guard let svgData = svgString.data(using: .utf8) else {
        newComponents.append(component)
        continue
      }
      
      let image = await createImage(from: svgData, geometry: geometry, xHeight: xHeight, displayScale: displayScale)

      newComponents.append(Component(text: component.text, type: component.type, renderedImage: image, imageOffset: offset))
    }

    return newComponents
  }
  
  @MainActor private func createImage(from svgData: Data, geometry: SVGGeometry, xHeight: CGFloat, displayScale: CGFloat) -> _Image? {
    let width = geometry.width.toPoints(xHeight)
    let height = geometry.height.toPoints(xHeight)
    let view = SVGView(data: svgData)
    let renderer = ImageRenderer(content: view.frame(width: width, height: height))
    renderer.scale = displayScale
#if os(iOS)
    return renderer.uiImage
#else
    return renderer.nsImage
#endif
  }
  
}

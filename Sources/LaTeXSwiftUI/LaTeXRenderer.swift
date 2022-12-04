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

internal class LaTeXRenderer {
  
  enum RenderingStyle {
    
    /// Render the entire text as the equation.
    case all
    
    /// Find equations in the text and only render the equations.
    case equations
  }
  
  /// The shared renderer.
  static let shared = LaTeXRenderer()
  
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
  func render(_ components: [LaTeXComponent], xHeight: CGFloat, displayScale: CGFloat) async throws -> [LaTeXComponent] {
    print("rendering!!!!")
    
    var newComponents = [LaTeXComponent]()
    for component in components {
      guard component.type.isEquation else {
        newComponents.append(component)
        continue
      }

      guard let svgString = try await mathjax?.tex2svg(component.text, inline: component.type.inline) else {
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

      newComponents.append(LaTeXComponent(text: component.text, type: component.type, renderedImage: image, imageOffset: offset))
    }

    return newComponents
  }
  
  @MainActor private func createImage(from svgData: Data, geometry: SVGGeometry, xHeight: CGFloat, displayScale: CGFloat) -> UIImage? {
    let width = geometry.width.toPoints(xHeight)
    let height = geometry.height.toPoints(xHeight)
    let view = SVGView(data: svgData)
    let renderer = ImageRenderer(content: view.frame(width: width, height: height))
    renderer.scale = displayScale
    return renderer.uiImage
  }
  
}

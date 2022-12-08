//
//  Renderer.swift
//  LaTeXSwiftUI
//
//  Created by Colin Campbell on 12/3/22.
//

import Foundation
import MathJaxSwift
import SwiftUI
import SVGView

#if os(iOS)
import UIKit
#else
import Cocoa
#endif

/// Renders equation components and updates their rendered image and offset
/// values.
internal class Renderer {
  
  // MARK: Static properties
  
  /// The shared renderer.
  static let shared = Renderer()
  
  // MARK: Private properties
  
  /// The MathJax instance.
  private let mathjax: MathJax?
  
  // MARK: Initializers
  
  /// Initializes a renderer with a MathJax instance.
  init() {
    do {
      mathjax = try MathJax(preferredOutputFormat: .svg)
    }
    catch {
      mathjax = nil
    }
  }
  
}

// MARK: Public methods

extension Renderer {
  
  /// Renders the view's component blocks.
  ///
  /// - Parameter colorScheme: The color scheme to render.
  func render(blocks: [ComponentBlock], xHeight: CGFloat, displayScale: CGFloat, color: Color?, colorScheme: ColorScheme = .light) -> [ComponentBlock] {
    var newBlocks = [ComponentBlock]()
    for block in blocks {
      do {
        let newComponents = try Renderer.shared.render(
          block.components,
          xHeight: xHeight,
          displayScale: displayScale,
          textColor: color ?? textColor(for: colorScheme))
        
        newBlocks.append(ComponentBlock(components: newComponents))
      }
      catch {
        continue
      }
    }
    
    return newBlocks
  }
  
  /// Renders the components and stores the new images in a new set of components.
  ///
  /// - Parameters:
  ///   - components: The components to render.
  ///   - xHeight: The xHeight of the font to use.
  ///   - displayScale: The current display scale.
  ///   - textColor: The text color.
  /// - Returns: An array of components.
  func render(
    _ components: [Component],
    xHeight: CGFloat,
    displayScale: CGFloat,
    textColor: Color
  ) throws -> [Component] {
    // Get the text color components
    guard let colorComponent = colorComponent(from: textColor) else {
      return components
    }
    
    // Iterate through the input components and render
    var renderedComponents = [Component]()
    for component in components {
      // Only render equation components
      guard component.type.isEquation else {
        renderedComponents.append(component)
        continue
      }
      
      // Colorize the component and get the SVG output
      let conversionOptions = ConversionOptions(display: !component.type.inline)
      guard let svgString = try mathjax?.tex2svg("\(colorComponent)\(component.text)", styles: false, conversionOptions: conversionOptions) else {
        renderedComponents.append(component)
        continue
      }
      
      // Get the SVG's geometry
      let geometry = try SVGGeometry(svg: svgString)
      
      // Get the SVG data
      guard let svgData = svgString.data(using: .utf8) else {
        renderedComponents.append(component)
        continue
      }
      
      // Save the rendered component
      renderedComponents.append(Component(
        text: component.text,
        type: component.type,
        svgData: svgData,
        svgGeometry: geometry))
    }
    
    // All done
    return renderedComponents
  }
  
  /// Creates an image from an SVG.
  ///
  /// - Parameters:
  ///   - svgData: The SVG data.
  ///   - geometry: The SVG's geometry.
  ///   - xHeight: The height of the `x` character to render.
  ///   - displayScale: The current display scale.
  /// - Returns: An image.
  @MainActor func convertToImage(
    svgData: Data,
    geometry: SVGGeometry,
    xHeight: CGFloat,
    displayScale: CGFloat
  ) -> _Image? {
    // Get the image's width and height
    let width = geometry.width.toPoints(xHeight)
    let height = geometry.height.toPoints(xHeight)
    
    // Render the view
    let view = SVGView(data: svgData)
    let renderer = ImageRenderer(content: view.frame(width: width, height: height))
    renderer.scale = displayScale
    
    // Return the rendered image
#if os(iOS)
    return renderer.uiImage
#else
    return renderer.nsImage
#endif
  }
  
}

// MARK: Private methods

extension Renderer {
  
  /// Creats a LaTeX color component from a SwiftUI color.
  ///
  /// - Parameter color: The color.
  /// - Returns: The LaTeX string to prepend to equations.
  /// Creats a LaTeX color component from a SwiftUI color.
  ///
  /// - Parameter color: The color.
  /// - Returns: The LaTeX string to prepend to equations.
  private func colorComponent(from color: Color) -> String? {
    let cgColor = _Color(color).cgColor
    guard let colorComponents = cgColor.components else {
      return nil
    }
    if colorComponents.count == 2 {
      return "\\definecolor{custom}{rgb}{\(colorComponents[0]), \(colorComponents[0]), \(colorComponents[0])} \\color{custom}"
    }
    else if colorComponents.count >= 3 {
      return "\\definecolor{custom}{rgb}{\(colorComponents[0]), \(colorComponents[1]), \(colorComponents[2])} \\color{custom}"
    }
    return nil
  }
  
  /// Gets the text color to use.
  ///
  /// - Parameter colorScheme: The current color scheme.
  /// - Returns: A color.
  private func textColor(for colorScheme: ColorScheme) -> Color {
#if os(iOS)
    return colorScheme == .dark ?
      Color(uiColor: .lightText) :
      Color(uiColor: .darkText)
#else
    return Color(nsColor: .textColor)
#endif
  }
  
}

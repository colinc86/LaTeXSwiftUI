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
      logError("Error creating MathJax instance: \(error)")
      mathjax = nil
    }
  }
  
}

// MARK: Public methods

extension Renderer {
  
  /// Renders the view's component blocks.
  ///
  /// - Parameters:
  ///   - blocks: The component blocks.
  ///   - xHeight: The font's ex value.
  ///   - displayScale: The display scale to render at.
  ///   - options: The MathJax Tex input processor options.
  /// - Returns: An array of rendered blocks.
  func render(
    blocks: [ComponentBlock],
    xHeight: CGFloat,
    displayScale: CGFloat,
    options: TexInputProcessorOptions
  ) -> [ComponentBlock] {
    var newBlocks = [ComponentBlock]()
    for block in blocks {
      do {
        let newComponents = try render(
          block.components,
          xHeight: xHeight,
          displayScale: displayScale,
          options: options)
        
        newBlocks.append(ComponentBlock(components: newComponents))
      }
      catch {
        logError("Error rendering block: \(error)")
        newBlocks.append(block)
        continue
      }
    }
    
    return newBlocks
  }
  
  /// Creates an image from an SVG.
  ///
  /// - Parameters:
  ///   - svgData: The SVG data.
  ///   - geometry: The SVG's geometry.
  ///   - xHeight: The height of the `x` character to render.
  ///   - displayScale: The current display scale.
  ///   - renderingMode: The image's rendering mode.
  /// - Returns: An image.
  @MainActor func convertToImage(
    svgData: Data,
    geometry: SVGGeometry,
    xHeight: CGFloat,
    displayScale: CGFloat,
    renderingMode: Image.TemplateRenderingMode
  ) -> Image? {
    // Get the image's width, height, and offset
    let width = geometry.width.toPoints(xHeight)
    let height = geometry.height.toPoints(xHeight)
    
    // Render the view
    let view = SVGView(data: svgData)
    let renderer = ImageRenderer(content: view.frame(width: width, height: height))
    
    // Create the image
    var image: Image?
#if os(iOS)
    renderer.scale = UIScreen.main.scale
    if let uiImage = renderer.uiImage {
      image = Image(uiImage: uiImage)
    }
#else
    renderer.scale = NSScreen.main?.scale
    if let nsImage = renderer.nsImage {
      image = Image(nsImage: nsImage)
    }
#endif
    
    return image?.renderingMode(renderingMode)
  }
  
}

// MARK: Private methods

extension Renderer {
  
  /// Renders the components and stores the new images in a new set of
  /// components.
  ///
  /// - Parameters:
  ///   - components: The components to render.
  ///   - xHeight: The xHeight of the font to use.
  ///   - displayScale: The current display scale.
  ///   - options: The MathJax TeX input processor options.
  /// - Returns: An array of components.
  private func render(
    _ components: [Component],
    xHeight: CGFloat,
    displayScale: CGFloat,
    options: TexInputProcessorOptions
  ) throws -> [Component] {
    // Iterate through the input components and render
    var renderedComponents = [Component]()
    for component in components {
      // Only render equation components
      guard component.type.isEquation else {
        renderedComponents.append(component)
        continue
      }
      
      // Create our options
      let conversionOptions = ConversionOptions(display: !component.type.inline)
      
      // Perform the conversion
      guard let svgString = try mathjax?.tex2svg(
        component.text,
        styles: false,
        conversionOptions: conversionOptions,
        inputOptions: options
      ) else {
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
  
}

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
  ///   - font: The view's font.
  ///   - displayScale: The display scale to render at.
  ///   - texOptions: The MathJax Tex input processor options.
  /// - Returns: An array of rendered blocks.
  func render(
    blocks: [ComponentBlock],
    font: Font,
    displayScale: CGFloat,
    texOptions: TexInputProcessorOptions
  ) -> [ComponentBlock] {
    let xHeight = _Font.preferredFont(from: font).xHeight
    var newBlocks = [ComponentBlock]()
    for block in blocks {
      do {
        let newComponents = try render(
          block.components,
          xHeight: xHeight,
          displayScale: displayScale,
          texOptions: texOptions)
        
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
  ///   - svg: The SVG.
  ///   - font: The view's font.
  ///   - displayScale: The current display scale.
  ///   - renderingMode: The image's rendering mode.
  /// - Returns: An image.
  @MainActor func convertToImage(
    svg: SVG,
    font: Font,
    displayScale: CGFloat,
    renderingMode: Image.TemplateRenderingMode
  ) -> Image? {
    // Get the image's width, height, and offset
    let xHeight = _Font.preferredFont(from: font).xHeight
    let width = svg.geometry.width.toPoints(xHeight)
    let height = svg.geometry.height.toPoints(xHeight)
    
    // Render the view
    let view = SVGView(data: svg.data)
    let renderer = ImageRenderer(content: view.frame(width: width, height: height))
    
    // Create the image
    var image: Image?
#if os(iOS)
    renderer.scale = UIScreen.main.scale
    if let uiImage = renderer.uiImage {
      image = Image(uiImage: uiImage)
    }
#else
    renderer.scale = NSScreen.main?.backingScaleFactor ?? 1
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
  ///   - texOptions: The MathJax TeX input processor options.
  /// - Returns: An array of components.
  private func render(
    _ components: [Component],
    xHeight: CGFloat,
    displayScale: CGFloat,
    texOptions: TexInputProcessorOptions
  ) throws -> [Component] {
    // Make sure we have a MathJax instance!
    guard let mathjax = mathjax else {
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
      
      // Create our options
      let conversionOptions = ConversionOptions(display: !component.type.inline)
      
      // Perform the conversion
      var conversionError: Error?
      let svgString = mathjax.tex2svg(
        component.text,
        styles: false,
        conversionOptions: conversionOptions,
        inputOptions: texOptions,
        error: &conversionError)
      
      // Check for a conversion error
      var errorText: String?
      if let mjError = conversionError as? MathJaxError, case .conversionError(let innerError) = mjError {
        errorText = innerError
      }
      else if let error = conversionError {
        throw error
      }
      
      // Create the SVG
      let svg = try SVG(svgString: svgString, errorText: errorText)
      
      // Save the rendered component
      renderedComponents.append(Component(
        text: component.text,
        type: component.type,
        svg: svg))
    }
    
    // All done
    return renderedComponents
  }
  
}

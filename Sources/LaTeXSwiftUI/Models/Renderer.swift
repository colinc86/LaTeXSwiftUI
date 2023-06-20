//
//  Renderer.swift
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
  
  // MARK: Internal properties
  
  /// The renderer's data and image cache.
  internal let cache = Cache()
  
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
      NSLog("Error creating MathJax instance: \(error)")
      mathjax = nil
    }
  }
  
}

// MARK: Public methods

extension Renderer {
  
  /// Determines and returns whether the blocks are in the renderer's cache.
  ///
  /// - Parameters:
  ///   - blocks: The blocks.
  ///   - font: The `font` environment variable.
  ///   - displayScale: The `displayScale` environment variable.
  ///   - texOptions: The `texOptions` environment variable.
  /// - Returns: Whether the blocks are in the renderer's cache.
  func blocksExistInCache(_ blocks: [ComponentBlock], font: Font, displayScale: CGFloat, texOptions: TeXInputProcessorOptions) -> Bool {
    for block in blocks {
      for component in block.components where component.type.isEquation {
        let dataCacheKey = Cache.SVGCacheKey(
          componentText: component.text,
          conversionOptions: component.conversionOptions,
          texOptions: texOptions)
        guard let svgData = cache.dataCacheValue(for: dataCacheKey) else {
          return false
        }
        
        guard let svg = try? SVG(data: svgData) else {
          return false
        }
        
        let xHeight = _Font.preferredFont(from: font).xHeight
        let imageCacheKey = Cache.ImageCacheKey(svg: svg, xHeight: xHeight)
        guard cache.imageCacheValue(for: imageCacheKey) != nil else {
          return false
        }
      }
    }
    return true
  }
  
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
    texOptions: TeXInputProcessorOptions
  ) async -> [ComponentBlock] {
    return await withCheckedContinuation({ continuation in
      continuation.resume(returning: render(blocks: blocks, font: font, displayScale: displayScale, texOptions: texOptions))
    })
  }
  
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
    texOptions: TeXInputProcessorOptions
  ) -> [ComponentBlock] {
    var newBlocks = [ComponentBlock]()
    for block in blocks {
      do {
        let newComponents = try render(
          block.components,
          xHeight: font.xHeight,
          displayScale: displayScale,
          texOptions: texOptions)
        
        newBlocks.append(ComponentBlock(components: newComponents))
      }
      catch {
        NSLog("Error rendering block: \(error)")
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
  /// - Returns: An image and its size.
  @MainActor func convertToImage(
    svg: SVG,
    font: Font,
    displayScale: CGFloat,
    renderingMode: Image.TemplateRenderingMode
  ) -> (Image, CGSize)? {
    // Create our cache key
    let cacheKey = Cache.ImageCacheKey(svg: svg, xHeight: font.xHeight)
    
    // Check the cache for an image
    if let image = cache.imageCacheValue(for: cacheKey) {
      return (Image(image: image)
        .renderingMode(renderingMode)
        .antialiased(true)
        .interpolation(.high), image.size)
    }
    
    // Continue with getting the image
    let width = svg.geometry.width.toPoints(font.xHeight)
    let height = svg.geometry.height.toPoints(font.xHeight)
    
    // Render the view
    let view = SVGView(data: svg.data)
    let renderer = ImageRenderer(content: view.frame(width: width, height: height))
#if os(iOS)
    renderer.scale = UIScreen.main.scale
    let image = renderer.image
#else
    renderer.scale = NSScreen.main?.backingScaleFactor ?? 1
    let image = renderer.image
#endif
    
    if let image = image {
      cache.setImageCacheValue(image, for: cacheKey)
      return (Image(image: image)
        .renderingMode(renderingMode)
        .antialiased(true)
        .interpolation(.high), image.size)
    }
    return nil
  }
  
}

// MARK: Private methods

extension Renderer {
  
  /// Gets the error text from a possibly non-nil error.
  ///
  /// - Parameter error: The error.
  /// - Returns: The error text.
  func getErrorText(from error: Error?) throws -> String? {
    if let mjError = error as? MathJaxError, case .conversionError(let innerError) = mjError {
      return innerError
    }
    else if let error = error {
      throw error
    }
    return nil
  }
  
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
    texOptions: TeXInputProcessorOptions
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
      
      // Create our cache key
      let cacheKey = Cache.SVGCacheKey(
        componentText: component.text,
        conversionOptions: component.conversionOptions,
        texOptions: texOptions)
      
      // Do we have the SVG in the cache?
      if let svgData = cache.dataCacheValue(for: cacheKey) {
        renderedComponents.append(Component(
          text: component.text,
          type: component.type,
          svg: try SVG(data: svgData)))
        continue
      }
      
      // Perform the conversion
      var conversionError: Error?
      let svgString = mathjax.tex2svg(
        component.text,
        styles: false,
        conversionOptions: component.conversionOptions,
        inputOptions: texOptions,
        error: &conversionError)
      
      // Check for a conversion error
      let errorText = try getErrorText(from: conversionError)
      
      // Create and cache the SVG
      let svg = try SVG(svgString: svgString, errorText: errorText)
      cache.setDataCacheValue(try svg.encoded(), for: cacheKey)
      
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

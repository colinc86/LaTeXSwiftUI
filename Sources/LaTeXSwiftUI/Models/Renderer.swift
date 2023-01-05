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

import CryptoKit
import Foundation
import MathJaxSwift
import Nuke
import SwiftUI
import SVGView

#if os(iOS)
import UIKit
#else
import Cocoa
#endif

fileprivate protocol Key: Codable {
  
  /// The key type used to identify the cache key in storage.
  static var keyType: String { get }
  
  /// A key to use if encoding fails.
  var fallbackKey: String { get }
  
}

extension Key {
  
  /// The key to use in the cache.
  func key() -> String {
    do {
      let data = try JSONEncoder().encode(self)
      let hashedData = SHA256.hash(data: data)
      return hashedData.compactMap { String(format: "%02x", $0) }.joined() + "-" + Self.keyType
    }
    catch {
      return fallbackKey + "-" + Self.keyType
    }
  }
  
}

/// Renders equation components and updates their rendered image and offset
/// values.
internal class Renderer {
  
  // MARK: Types
  
  /// An SVG cache key.
  struct SVGCacheKey: Key {
    static let keyType: String = "svg"
    let componentText: String
    let conversionOptions: ConversionOptions
    let texOptions: TeXInputProcessorOptions
    internal var fallbackKey: String { componentText }
  }
  
  /// An image cache key.
  struct ImageCacheKey: Key {
    static let keyType: String = "image"
    let svg: SVG
    let xHeight: CGFloat
    internal var fallbackKey: String { String(data: svg.data, encoding: .utf8) ?? "" }
  }
  
  // MARK: Static properties
  
  /// The shared renderer.
  static let shared = Renderer()
  
  // MARK: Private properties
  
  /// The MathJax instance.
  private let mathjax: MathJax?
  
  /// The renderer's data cache.
  internal let dataCache: DataCache?
  
  /// The renderer's image cache.
  internal let imageCache: ImageCache
  
  // MARK: Initializers
  
  /// Initializes a renderer with a MathJax instance.
  init() {
    do {
      dataCache = try DataCache(name: "mathJaxRenderDataCache")
    }
    catch {
      NSLog("Error creating DataCache instance: \(error)")
      dataCache = nil
    }
    
    imageCache = ImageCache()
    
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
    // Get the image's width, height, and offset
    let xHeight = _Font.preferredFont(from: font).xHeight
    
    // Create our cache key
    let cacheKey = ImageCacheKey(svg: svg, xHeight: xHeight)
    
    // Check the cache for an image
    if let image = imageCache[Nuke.ImageCacheKey(key: cacheKey.key())]?.image {
      return (Image(image: image)
        .renderingMode(renderingMode)
        .antialiased(true)
        .interpolation(.high), image.size)
    }
    
    // Continue with getting the image
    let width = svg.geometry.width.toPoints(xHeight)
    let height = svg.geometry.height.toPoints(xHeight)
    
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
      imageCache[Nuke.ImageCacheKey(key: cacheKey.key())] = ImageContainer(image: image)
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
      
      // Create our options
      let conversionOptions = ConversionOptions(display: !component.type.inline)
      
      // Create our cache key
      let cacheKey = SVGCacheKey(
        componentText: component.text,
        conversionOptions: conversionOptions,
        texOptions: texOptions)
      
      // Do we have the SVG in the cache?
      if let svgData = dataCache?[cacheKey.key()] {
        renderedComponents.append(Component(
          text: component.text,
          type: component.type,
          svg: try JSONDecoder().decode(SVG.self, from: svgData)))
        continue
      }
      
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
      dataCache?[cacheKey.key()] = try JSONEncoder().encode(svg)
      
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

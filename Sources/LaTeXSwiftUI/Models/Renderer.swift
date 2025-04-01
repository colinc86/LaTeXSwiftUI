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
import SwiftDraw
import SwiftUI

#if os(iOS) || os(visionOS)
import UIKit
#else
import Cocoa
#endif

/// Renders equation components and updates their rendered image and offset
/// values.
internal class Renderer: ObservableObject {
  
  // MARK: Types
  
  /// A set of values used to create an array of parsed component blocks.
  struct ParsingSource: Equatable {
    
    /// The LaTeX input.
    let latex: String
    
    /// Whether or not the HTML should be unencoded.
    let unencodeHTML: Bool
    
    /// The parsing mode.
    let parsingMode: LaTeX.ParsingMode
  }
  
  // MARK: Public properties
  
  /// Whether or not the view's blocks have been rendered.
  @MainActor @Published var rendered: Bool = false
  
  /// Whether or not the view's blocks have been rendered synchronously.
  @MainActor var syncRendered: Bool = false
  
  /// Whether or not the receiver is currently rendering.
  @MainActor var isRendering: Bool = false
  
  /// The rendered blocks.
  @MainActor var blocks: [ComponentBlock] = []
  
  // MARK: Private properties
  
  /// The LaTeX input's parsed blocks.
  private var _parsedBlocks: [ComponentBlock]? = nil
  private var parsedBlocks: [ComponentBlock]? {
    get {
      parsedBlocksQueue.sync { [weak self] in
        return self?._parsedBlocks
      }
    }
    
    set {
      parsedBlocksQueue.async(flags: .barrier) { [weak self] in
        self?._parsedBlocks = newValue
      }
    }
  }
  
  /// The set of values used to create the parsed blocks.
  private var _parsingSource: ParsingSource? = nil
  
  /// Queue for accessing parsed blocks.
  private var parsedBlocksQueue = DispatchQueue(label: "latexswiftui.renderer.parse")
  
}

// MARK: Public methods

extension Renderer {
  
  /// Returns whether the view's components are cached.
  ///
  /// - Parameters:
  ///   - latex: The LaTeX input string.
  ///   - unencodeHTML: The `unencodeHTML` environment variable.
  ///   - parsingMode: The `parsingMode` environment variable.
  ///   - processEscapes: The `processEscapes` environment variable.
  ///   - errorMode: The `errorMode` environment variable.
  ///   - font: The `font environment` variable.
  ///   - displayScale: The `displayScale` environment variable.
  func isCached(
    latex: String,
    unencodeHTML: Bool,
    parsingMode: LaTeX.ParsingMode,
    processEscapes: Bool,
    errorMode: LaTeX.ErrorMode,
    font: Font,
    displayScale: CGFloat
  ) -> Bool {
    let texOptions = TeXInputProcessorOptions(processEscapes: processEscapes, errorMode: errorMode)
    return blocksExistInCache(
      parseBlocks(latex: latex, unencodeHTML: unencodeHTML, parsingMode: parsingMode),
      font: font,
      displayScale: displayScale,
      texOptions: texOptions)
  }
  
  /// Renders the view's components synchronously.
  ///
  /// - Parameters:
  ///   - latex: The LaTeX input string.
  ///   - unencodeHTML: The `unencodeHTML` environment variable.
  ///   - parsingMode: The `parsingMode` environment variable.
  ///   - processEscapes: The `processEscapes` environment variable.
  ///   - errorMode: The `errorMode` environment variable.
  ///   - font: The `font` environment variable.
  ///   - displayScale: The `displayScale` environment variable.
  ///   - renderingMode: The `renderingMode` environment variable.
  @MainActor func renderSync(
    latex: String,
    unencodeHTML: Bool,
    parsingMode: LaTeX.ParsingMode,
    processEscapes: Bool,
    errorMode: LaTeX.ErrorMode,
    font: Font,
    displayScale: CGFloat,
    renderingMode: SwiftUI.Image.TemplateRenderingMode
  ) -> [ComponentBlock] {
    guard !isRendering else {
      return []
    }
    guard !rendered && !syncRendered else {
      return blocks
    }
    isRendering = true
    
    let texOptions = TeXInputProcessorOptions(processEscapes: processEscapes, errorMode: errorMode)
    blocks = render(
      blocks: parseBlocks(latex: latex, unencodeHTML: unencodeHTML, parsingMode: parsingMode),
      font: font,
      displayScale: displayScale,
      renderingMode: renderingMode,
      texOptions: texOptions)
    
    isRendering = false
    syncRendered = true
    return blocks
  }
  
  /// Renders the view's components asynchronously.
  ///
  /// - Parameters:
  ///   - latex: The LaTeX input string.
  ///   - unencodeHTML: The `unencodeHTML` environment variable.
  ///   - parsingMode: The `parsingMode` environment variable.
  ///   - processEscapes: The `processEscapes` environment variable.
  ///   - errorMode: The `errorMode` environment variable.
  ///   - font: The `font` environment variable.
  ///   - displayScale: The `displayScale` environment variable.
  ///   - renderingMode: The `renderingMode` environment variable.
  func render(
    latex: String,
    unencodeHTML: Bool,
    parsingMode: LaTeX.ParsingMode,
    processEscapes: Bool,
    errorMode: LaTeX.ErrorMode,
    font: Font,
    displayScale: CGFloat,
    renderingMode: SwiftUI.Image.TemplateRenderingMode
  ) async {
    let isRen = await isRendering
    let ren = await rendered
    let renSync = await syncRendered
    guard !isRen && !ren && !renSync else {
      return
    }
    await MainActor.run {
      isRendering = true
    }
    
    let texOptions = TeXInputProcessorOptions(processEscapes: processEscapes, errorMode: errorMode)
    let renderedBlocks = render(
      blocks: parseBlocks(latex: latex, unencodeHTML: unencodeHTML, parsingMode: parsingMode),
      font: font,
      displayScale: displayScale,
      renderingMode: renderingMode,
      texOptions: texOptions)
    
    await MainActor.run {
      blocks = renderedBlocks
      isRendering = false
      rendered = true
    }
  }
  
}

// MARK: Private methods

extension Renderer {
  
  /// Gets the LaTeX input's parsed blocks.
  ///
  /// - Parameters:
  ///   - latex: The LaTeX input string.
  ///   - unencodeHTML: The `unencodeHTML` environment variable.
  ///   - parsingMode: The `parsingMode` environment variable.
  /// - Returns: The parsed blocks.
  private func parseBlocks(
    latex: String,
    unencodeHTML: Bool,
    parsingMode: LaTeX.ParsingMode
  ) -> [ComponentBlock] {
    if let parsedBlocks {
      return parsedBlocks
    }
    
    let currentSource = ParsingSource(latex: latex, unencodeHTML: unencodeHTML, parsingMode: parsingMode)
    if let _parsedBlocks, _parsingSource == currentSource {
      return _parsedBlocks
    }
    
    let blocks = Parser.parse(unencodeHTML ? latex.htmlUnescape() : latex, mode: parsingMode)
    parsedBlocks = blocks
    _parsingSource = currentSource
    return blocks
  }
  
  /// Renders the view's component blocks.
  ///
  /// - Parameters:
  ///   - blocks: The component blocks.
  ///   - font: The view's font.
  ///   - displayScale: The display scale to render at.
  ///   - renderingMode: The image rendering mode.
  ///   - texOptions: The MathJax Tex input processor options.
  /// - Returns: An array of rendered blocks.
  func render(
    blocks: [ComponentBlock],
    font: Font,
    displayScale: CGFloat,
    renderingMode: SwiftUI.Image.TemplateRenderingMode,
    texOptions: TeXInputProcessorOptions
  ) -> [ComponentBlock] {
    var newBlocks = [ComponentBlock]()
    for block in blocks {
      do {
        let newComponents = try render(
          block.components,
          xHeight: font.xHeight,
          displayScale: displayScale,
          renderingMode: renderingMode,
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
  
  /// Renders the components and stores the new images in a new set of
  /// components.
  ///
  /// - Parameters:
  ///   - components: The components to render.
  ///   - xHeight: The xHeight of the font to use.
  ///   - displayScale: The current display scale.
  ///   - renderingMode: The image rendering mode.
  ///   - texOptions: The MathJax TeX input processor options.
  /// - Returns: An array of components.
  private func render(
    _ components: [Component],
    xHeight: CGFloat,
    displayScale: CGFloat,
    renderingMode: SwiftUI.Image.TemplateRenderingMode,
    texOptions: TeXInputProcessorOptions
  ) throws -> [Component] {
    // Iterate through the input components and render
    var renderedComponents = [Component]()
    for component in components {
      // Only render equation components
      guard component.type.isEquation else {
        renderedComponents.append(component)
        continue
      }
      
      // Get the svg
      guard let svg = try getSVG(for: component, texOptions: texOptions) else {
        renderedComponents.append(component)
        continue
      }
      
      // Get the image
      guard let image = getImage(for: svg, xHeight: xHeight, displayScale: displayScale, renderingMode: renderingMode) else {
        renderedComponents.append(Component(text: component.text, type: component.type, svg: svg))
        continue
      }
      
      // Save the rendered component
      renderedComponents.append(Component(
        text: component.text,
        type: component.type,
        svg: svg,
        imageContainer: ImageContainer(
          image: image,
          size: HashableCGSize(svg.size(for: xHeight))
        )
      ))
    }
    
    // All done
    return renderedComponents
  }
  
  /// Gets the component's SVG, if possible.
  ///
  /// The SVG cache is checked first.
  ///
  /// - Parameters:
  ///   - component: The component.
  ///   - texOptions: The TeX input processor options to use.
  /// - Returns: An SVG.
  func getSVG(
    for component: Component,
    texOptions: TeXInputProcessorOptions
  ) throws -> SVG? {
    // Create our SVG cache key
    let svgCacheKey = Cache.SVGCacheKey(
      componentText: component.text,
      conversionOptions: component.conversionOptions,
      texOptions: texOptions)
    
    // Do we have the SVG in the cache?
    if let svgData = Cache.shared.dataCacheValue(for: svgCacheKey) {
      return try SVG(data: svgData)
    }
    
    // Make sure we have a MathJax instance!
    guard let mathjax = MathJax.svgRenderer else {
      return nil
    }
    
    // Perform the TeX -> SVG conversion
    var conversionError: Error?
    let svgString = mathjax.tex2svg(
      component.text,
      styles: false,
      conversionOptions: component.conversionOptions,
      inputOptions: texOptions,
      error: &conversionError)
    
    // Check for a conversion error
    let errorText = try getErrorText(from: conversionError)
    
    // Create the SVG
    let svg = try SVG(svgString: svgString, errorText: errorText)
    
    // Set the SVG in the cache
    Cache.shared.setDataCacheValue(try svg.encoded(), for: svgCacheKey)
    
    // Finish up
    return svg
  }
  
  /// Gets the component's image, if possible.
  ///
  /// The image cache is checked first.
  ///
  /// - Parameters:
  ///   - svg: The component's SVG.
  ///   - xHeight: The current font's x-height.
  ///   - displayScale: The display scale.
  ///   - renderingMode: The image rendering mode.
  /// - Returns: The image.
  func getImage(
    for svg: SVG,
    xHeight: CGFloat,
    displayScale: CGFloat,
    renderingMode: SwiftUI.Image.TemplateRenderingMode
  ) -> SwiftUI.Image? {
    // Create our cache key
    let cacheKey = Cache.ImageCacheKey(svg: svg, xHeight: xHeight)
    
    // Check the cache for an image
    if let image = Cache.shared.imageCacheValue(for: cacheKey) {
      return Image(image: image)
        .renderingMode(renderingMode)
        .antialiased(true)
        .interpolation(.high)
    }
    
    // Continue with getting the image
    let imageSize = svg.size(for: xHeight)
    #if os(iOS) || os(visionOS)
    guard let image = SwiftDraw.SVG(data: svg.data)?.rasterize(size: imageSize, scale: displayScale) else {
      return nil
    }
    #else
    guard let image = SwiftDraw.SVG(data: svg.data)?.rasterize(with: imageSize, scale: displayScale) else {
      return nil
    }
    #endif
    
    // Set the image in the cache
    Cache.shared.setImageCacheValue(image, for: cacheKey)
    
    // Finish up
    return Image(image: image, scale: displayScale)
      .renderingMode(renderingMode)
      .antialiased(true)
      .interpolation(.high)
  }
  
  /// Gets the error text from a possibly non-nil error.
  ///
  /// - Parameter error: The error.
  /// - Returns: The error text.
  private func getErrorText(from error: Error?) throws -> String? {
    if let mjError = error as? MathJaxError, case .conversionError(let innerError) = mjError {
      return innerError
    }
    else if let error = error {
      throw error
    }
    return nil
  }
  
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
        guard let svgData = Cache.shared.dataCacheValue(for: dataCacheKey) else {
          return false
        }
        
        guard let svg = try? SVG(data: svgData) else {
          return false
        }
        
        let xHeight = _Font.preferredFont(from: font).xHeight
        let imageCacheKey = Cache.ImageCacheKey(svg: svg, xHeight: xHeight)
        guard Cache.shared.imageCacheValue(for: imageCacheKey) != nil else {
          return false
        }
      }
    }
    return true
  }
  
}

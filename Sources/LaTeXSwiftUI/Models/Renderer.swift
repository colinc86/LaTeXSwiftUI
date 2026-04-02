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
@MainActor internal class Renderer: ObservableObject {

  // MARK: Static properties

  /// A dedicated serial queue for MathJax and rasterization work.
  /// JSContext must be accessed from a consistent thread.
  nonisolated private static let renderQueue = DispatchQueue(
    label: "latexswiftui.renderer.render",
    qos: .userInitiated)

  /// The shared MathJax instance. Swift's `static let` guarantees
  /// thread-safe one-time initialization. All subsequent access to
  /// this instance must go through `renderQueue` to keep JSContext
  /// on a consistent thread.
  nonisolated(unsafe) private static let mathjax: MathJax? = {
    do {
      return try MathJax(preferredOutputFormats: [.svg, .speech])
    }
    catch {
      NSLog("Error creating MathJax instance: \(error)")
      return nil
    }
  }()

  // MARK: Types
  
  /// A set of values used to create an array of parsed component blocks.
  struct ParsingSource: Equatable, Sendable {
    
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
  
  /// Resets the renderer so it can re-render with new input.
  @MainActor func reset() {
    rendered = false
    syncRendered = false
    isRendering = false
    blocks = []
    parsedBlocks = nil
    _parsingSource = nil
  }

  /// The LaTeX input's parsed blocks.
  nonisolated(unsafe) private var parsedBlocks: [ComponentBlock]? = nil

  /// The set of values used to create the parsed blocks.
  nonisolated(unsafe) private var _parsingSource: ParsingSource? = nil
  
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
  ///   - xHeight: The font's x-height.
  ///   - displayScale: The `displayScale` environment variable.
  func isCached(
    latex: String,
    unencodeHTML: Bool,
    parsingMode: LaTeX.ParsingMode,
    processEscapes: Bool,
    errorMode: LaTeX.ErrorMode,
    xHeight: CGFloat,
    displayScale: CGFloat
  ) -> Bool {
    let texOptions = TeXInputProcessorOptions(processEscapes: processEscapes, errorMode: errorMode)
    return blocksExistInCache(
      parseBlocks(latex: latex, unencodeHTML: unencodeHTML, parsingMode: parsingMode),
      xHeight: xHeight,
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
  ///   - xHeight: The font's x-height.
  ///   - displayScale: The `displayScale` environment variable.
  ///   - renderingMode: The `renderingMode` environment variable.
  @MainActor func renderSync(
    latex: String,
    unencodeHTML: Bool,
    parsingMode: LaTeX.ParsingMode,
    processEscapes: Bool,
    errorMode: LaTeX.ErrorMode,
    xHeight: CGFloat,
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

    // Dispatch to the render queue to keep JSContext access on a
    // consistent thread.
    blocks = Self.renderQueue.sync { [self] in
      let texOptions = TeXInputProcessorOptions(processEscapes: processEscapes, errorMode: errorMode)
      return render(
        blocks: parseBlocks(latex: latex, unencodeHTML: unencodeHTML, parsingMode: parsingMode),
        xHeight: xHeight,
        displayScale: displayScale,
        renderingMode: renderingMode,
        texOptions: texOptions)
    }

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
  ///   - xHeight: The font's x-height.
  ///   - displayScale: The `displayScale` environment variable.
  ///   - renderingMode: The `renderingMode` environment variable.
  func render(
    latex: String,
    unencodeHTML: Bool,
    parsingMode: LaTeX.ParsingMode,
    processEscapes: Bool,
    errorMode: LaTeX.ErrorMode,
    xHeight: CGFloat,
    displayScale: CGFloat,
    renderingMode: SwiftUI.Image.TemplateRenderingMode
  ) async {
    guard !isRendering && !rendered && !syncRendered else { return }
    isRendering = true

    let renderedBlocks = await renderOffMain(
      latex: latex,
      unencodeHTML: unencodeHTML,
      parsingMode: parsingMode,
      processEscapes: processEscapes,
      errorMode: errorMode,
      xHeight: xHeight,
      displayScale: displayScale,
      renderingMode: renderingMode)

    blocks = renderedBlocks
    isRendering = false
    rendered = true
  }

  /// Performs parsing and rendering on the dedicated render queue.
  nonisolated private func renderOffMain(
    latex: String,
    unencodeHTML: Bool,
    parsingMode: LaTeX.ParsingMode,
    processEscapes: Bool,
    errorMode: LaTeX.ErrorMode,
    xHeight: CGFloat,
    displayScale: CGFloat,
    renderingMode: SwiftUI.Image.TemplateRenderingMode
  ) async -> [ComponentBlock] {
    await withCheckedContinuation { continuation in
      Self.renderQueue.async { [self] in
        let parsedBlocks = parseBlocks(
          latex: latex, unencodeHTML: unencodeHTML, parsingMode: parsingMode)
        let texOptions = TeXInputProcessorOptions(
          processEscapes: processEscapes, errorMode: errorMode)
        let result = render(
          blocks: parsedBlocks,
          xHeight: xHeight,
          displayScale: displayScale,
          renderingMode: renderingMode,
          texOptions: texOptions)
        continuation.resume(returning: result)
      }
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
  nonisolated private func parseBlocks(
    latex: String,
    unencodeHTML: Bool,
    parsingMode: LaTeX.ParsingMode
  ) -> [ComponentBlock] {
    let currentSource = ParsingSource(latex: latex, unencodeHTML: unencodeHTML, parsingMode: parsingMode)
    if let parsedBlocks, _parsingSource == currentSource {
      return parsedBlocks
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
  ///   - xHeight: The font's x-height.
  ///   - displayScale: The display scale to render at.
  ///   - renderingMode: The image rendering mode.
  ///   - texOptions: The MathJax Tex input processor options.
  /// - Returns: An array of rendered blocks.
  nonisolated func render(
    blocks: [ComponentBlock],
    xHeight: CGFloat,
    displayScale: CGFloat,
    renderingMode: SwiftUI.Image.TemplateRenderingMode,
    texOptions: TeXInputProcessorOptions
  ) -> [ComponentBlock] {
    var newBlocks = [ComponentBlock]()
    for block in blocks {
      do {
        let newComponents = try render(
          block.components,
          xHeight: xHeight,
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
  ///   - xHeight: The font's x-height.
  ///   - displayScale: The current display scale.
  ///   - renderingMode: The image rendering mode.
  ///   - texOptions: The MathJax TeX input processor options.
  /// - Returns: An array of components.
  nonisolated private func render(
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
  nonisolated func getSVG(
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
    guard let mathjax = Self.mathjax else {
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

    // Generate speech text for accessibility via the Speech Rule Engine
    let speechText = try? mathjax.tex2speech(
      component.text,
      conversionOptions: component.conversionOptions,
      inputOptions: texOptions)

    // Create the SVG
    let svg = try SVG(svgString: svgString, errorText: errorText, speechText: speechText)
    
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
  nonisolated func getImage(
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

    // Rasterize the SVG using a thread-safe CGBitmapContext
    let imageSize = svg.size(for: xHeight)
    guard let image = Self.rasterizeSVG(
      data: svg.data, size: imageSize, scale: displayScale
    ) else {
      return nil
    }

    // Set the image in the cache
    Cache.shared.setImageCacheValue(image, for: cacheKey)

    // Finish up
    return Image(image: image, scale: displayScale)
      .renderingMode(renderingMode)
      .antialiased(true)
      .interpolation(.high)
  }
  
  /// Rasterizes SVG data to a platform image using a thread-safe
  /// CGBitmapContext.
  ///
  /// - Parameters:
  ///   - data: The SVG data.
  ///   - size: The logical size of the image.
  ///   - scale: The display scale.
  /// - Returns: A platform image, or nil on failure.
  nonisolated private static func rasterizeSVG(
    data: Data, size: CGSize, scale: CGFloat
  ) -> _Image? {
    guard let svg = SwiftDraw.SVG(data: data) else { return nil }
    let pixelWidth = Int(ceil(size.width * scale))
    let pixelHeight = Int(ceil(size.height * scale))
    guard pixelWidth > 0, pixelHeight > 0 else { return nil }

    guard let ctx = CGContext(
      data: nil,
      width: pixelWidth,
      height: pixelHeight,
      bitsPerComponent: 8,
      bytesPerRow: 0,
      space: CGColorSpaceCreateDeviceRGB(),
      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else { return nil }

    // Flip the coordinate system (CGContext origin is bottom-left,
    // but SVG expects top-left).
    ctx.translateBy(x: 0, y: CGFloat(pixelHeight))
    ctx.scaleBy(x: scale, y: -scale)
    ctx.draw(svg, in: CGRect(origin: .zero, size: size))

    guard let cgImage = ctx.makeImage() else { return nil }

    #if os(iOS) || os(visionOS)
    return UIImage(cgImage: cgImage, scale: scale, orientation: .up)
    #else
    return NSImage(cgImage: cgImage, size: size)
    #endif
  }

  /// Gets the error text from a possibly non-nil error.
  ///
  /// - Parameter error: The error.
  /// - Returns: The error text.
  nonisolated private func getErrorText(from error: Error?) throws -> String? {
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
  ///   - xHeight: The font's x-height.
  ///   - displayScale: The `displayScale` environment variable.
  ///   - texOptions: The `texOptions` environment variable.
  /// - Returns: Whether the blocks are in the renderer's cache.
  nonisolated func blocksExistInCache(_ blocks: [ComponentBlock], xHeight: CGFloat, displayScale: CGFloat, texOptions: TeXInputProcessorOptions) -> Bool {
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
        
        let imageCacheKey = Cache.ImageCacheKey(svg: svg, xHeight: xHeight)
        guard Cache.shared.imageCacheValue(for: imageCacheKey) != nil else {
          return false
        }
      }
    }
    return true
  }
  
}

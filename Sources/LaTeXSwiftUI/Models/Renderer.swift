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

  /// Wraps the notation-specific MathJax input processor options.
  enum InputOptions: Codable {
    case tex(TeXInputProcessorOptions)
    case mml(MMLInputProcessorOptions)
    case am(AMInputProcessorOptions)
  }

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
  ///   - notation: The `notation` environment variable.
  ///   - processEscapes: The `processEscapes` environment variable.
  ///   - errorMode: The `errorMode` environment variable.
  ///   - xHeight: The font's x-height.
  ///   - displayScale: The `displayScale` environment variable.
  func isCached(
    latex: String,
    unencodeHTML: Bool,
    parsingMode: LaTeX.ParsingMode,
    notation: LaTeX.Notation,
    processEscapes: Bool,
    errorMode: LaTeX.ErrorMode,
    texPackages: Set<LaTeX.TeXPackage>?,
    texAutoload: Bool = true,
    xHeight: CGFloat,
    displayScale: CGFloat
  ) -> Bool {
    return blocksExistInCache(
      parseBlocks(latex: latex, unencodeHTML: unencodeHTML, parsingMode: parsingMode),
      xHeight: xHeight,
      displayScale: displayScale,
      notation: notation,
      processEscapes: processEscapes,
      errorMode: errorMode,
      texPackages: texPackages,
      texAutoload: texAutoload)
  }
  
  /// Renders the view's components synchronously.
  ///
  /// - Parameters:
  ///   - latex: The LaTeX input string.
  ///   - unencodeHTML: The `unencodeHTML` environment variable.
  ///   - parsingMode: The `parsingMode` environment variable.
  ///   - notation: The `notation` environment variable.
  ///   - processEscapes: The `processEscapes` environment variable.
  ///   - errorMode: The `errorMode` environment variable.
  ///   - xHeight: The font's x-height.
  ///   - displayScale: The `displayScale` environment variable.
  ///   - renderingMode: The `renderingMode` environment variable.
  @MainActor func renderSync(
    latex: String,
    unencodeHTML: Bool,
    parsingMode: LaTeX.ParsingMode,
    notation: LaTeX.Notation,
    processEscapes: Bool,
    errorMode: LaTeX.ErrorMode,
    noCache: Bool = false,
    speechLocale: String = "en",
    speechStyle: LaTeX.SpeechStyle = .default,
    texPackages: Set<LaTeX.TeXPackage>? = nil,
    texAutoload: Bool = true,
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

    blocks = Self.renderQueue.sync { [self] in
      return render(
        blocks: parseBlocks(latex: latex, unencodeHTML: unencodeHTML, parsingMode: parsingMode),
        xHeight: xHeight,
        displayScale: displayScale,
        renderingMode: renderingMode,
        notation: notation,
        processEscapes: processEscapes,
        errorMode: errorMode,
        noCache: noCache,
        speechLocale: speechLocale,
        speechStyle: speechStyle,
        texPackages: texPackages,
        texAutoload: texAutoload)
    }

    isRendering = false
    syncRendered = true
    return blocks
  }

  func render(
    latex: String,
    unencodeHTML: Bool,
    parsingMode: LaTeX.ParsingMode,
    notation: LaTeX.Notation,
    processEscapes: Bool,
    errorMode: LaTeX.ErrorMode,
    noCache: Bool = false,
    speechLocale: String = "en",
    speechStyle: LaTeX.SpeechStyle = .default,
    texPackages: Set<LaTeX.TeXPackage>? = nil,
    texAutoload: Bool = true,
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
      notation: notation,
      processEscapes: processEscapes,
      errorMode: errorMode,
      noCache: noCache,
      speechLocale: speechLocale,
      speechStyle: speechStyle,
      texPackages: texPackages,
      texAutoload: texAutoload,
      xHeight: xHeight,
      displayScale: displayScale,
      renderingMode: renderingMode)

    blocks = renderedBlocks
    isRendering = false
    rendered = true
  }

  nonisolated private func renderOffMain(
    latex: String,
    unencodeHTML: Bool,
    parsingMode: LaTeX.ParsingMode,
    notation: LaTeX.Notation,
    processEscapes: Bool,
    errorMode: LaTeX.ErrorMode,
    noCache: Bool,
    speechLocale: String,
    speechStyle: LaTeX.SpeechStyle,
    texPackages: Set<LaTeX.TeXPackage>?,
    texAutoload: Bool,
    xHeight: CGFloat,
    displayScale: CGFloat,
    renderingMode: SwiftUI.Image.TemplateRenderingMode
  ) async -> [ComponentBlock] {
    await withCheckedContinuation { continuation in
      Self.renderQueue.async { [self] in
        let parsedBlocks = parseBlocks(
          latex: latex, unencodeHTML: unencodeHTML, parsingMode: parsingMode)
        let result = render(
          blocks: parsedBlocks,
          xHeight: xHeight,
          displayScale: displayScale,
          renderingMode: renderingMode,
          notation: notation,
          processEscapes: processEscapes,
          errorMode: errorMode,
          noCache: noCache,
          speechLocale: speechLocale,
          speechStyle: speechStyle,
          texPackages: texPackages,
          texAutoload: texAutoload)
        continuation.resume(returning: result)
      }
    }
  }
  
  /// Renders an input string to an array of platform images (one per equation).
  ///
  /// This method runs the full rendering pipeline on the dedicated render queue
  /// and returns `UIImage`/`NSImage` instances directly.
  ///
  /// - Parameters:
  ///   - latex: The input string.
  ///   - unencodeHTML: Whether to unencode HTML entities.
  ///   - parsingMode: The parsing mode.
  ///   - notation: The input notation format.
  ///   - processEscapes: Whether to process escape sequences.
  ///   - errorMode: The error mode.
  ///   - xHeight: The font's x-height in points.
  ///   - displayScale: The display scale factor.
  /// - Returns: An array of rendered platform images.
  nonisolated static func renderToPlatformImages(
    latex: String,
    unencodeHTML: Bool,
    parsingMode: LaTeX.ParsingMode,
    notation: LaTeX.Notation,
    processEscapes: Bool,
    errorMode: LaTeX.ErrorMode,
    texPackages: Set<LaTeX.TeXPackage>? = nil,
    texAutoload: Bool = true,
    xHeight: CGFloat,
    displayScale: CGFloat
  ) -> [_Image] {
    renderQueue.sync {
      let svgOutputOptions = SVGOutputProcessorOptions()

      let input = unencodeHTML ? latex.htmlUnescape() : latex
      let blocks = Parser.parse(input, mode: parsingMode)
      var images = [_Image]()

      for block in blocks {
        for component in block.components where component.type.isEquation {
          let inputOptions = resolveInputOptions(
            for: component, notation: notation,
            processEscapes: processEscapes, errorMode: errorMode,
            texPackages: texPackages, texAutoload: texAutoload)
          guard let svg = try? getSVGStatic(for: component, inputOptions: inputOptions, svgOutputOptions: svgOutputOptions) else {
            continue
          }
          let imageSize = svg.size(for: xHeight)
          guard let image = rasterizeSVG(data: svg.data, size: imageSize, scale: displayScale) else {
            continue
          }
          images.append(image)
        }
      }

      return images
    }
  }

  /// Validates an equation string by attempting a conversion with
  /// error-suppressing packages removed (for TeX notation).
  ///
  /// When `notation` is `.auto`, each notation is tried in order. The input
  /// is considered valid if any notation succeeds.
  ///
  /// Must not be called from `renderQueue`.
  ///
  /// - Parameters:
  ///   - latex: The raw equation string (no delimiters).
  ///   - notation: The input notation format.
  ///   - processEscapes: Whether to process escape sequences (TeX only).
  /// - Throws: ``LaTeX/ValidationError`` if the input is invalid.
  nonisolated static func validate(
    latex: String,
    notation: LaTeX.Notation,
    processEscapes: Bool
  ) throws {
    try renderQueue.sync {
      guard let mathjax = mathjax else {
        return
      }

      if notation == .auto {
        let detected = sniffNotation(latex)
        let inputOptions = makeInputOptions(notation: detected, processEscapes: processEscapes, errorMode: .error)
        let conversionOptions = ConversionOptions(display: false)

        var conversionError: Error?
        switch inputOptions {
        case .tex(let opts):
          _ = mathjax.tex2svg(
            latex, styles: false, conversionOptions: conversionOptions,
            inputOptions: opts, error: &conversionError)
        case .mml(let opts):
          _ = mathjax.mml2svg(
            latex, styles: false, conversionOptions: conversionOptions,
            inputOptions: opts, error: &conversionError)
        case .am(let opts):
          _ = mathjax.am2svg(
            latex, styles: false, conversionOptions: conversionOptions,
            inputOptions: opts, error: &conversionError)
        }

        if let mjError = conversionError as? MathJaxError,
           case .conversionError(let innerError) = mjError {
          throw LaTeX.ValidationError(message: innerError)
        } else if let error = conversionError {
          throw error
        }
        return
      }

      let inputOptions = makeInputOptions(notation: notation, processEscapes: processEscapes, errorMode: .error)
      let conversionOptions = ConversionOptions(display: false)

      var conversionError: Error?
      switch inputOptions {
      case .tex(let opts):
        _ = mathjax.tex2svg(
          latex, styles: false, conversionOptions: conversionOptions,
          inputOptions: opts, error: &conversionError)
      case .mml(let opts):
        _ = mathjax.mml2svg(
          latex, styles: false, conversionOptions: conversionOptions,
          inputOptions: opts, error: &conversionError)
      case .am(let opts):
        _ = mathjax.am2svg(
          latex, styles: false, conversionOptions: conversionOptions,
          inputOptions: opts, error: &conversionError)
      }

      if let mjError = conversionError as? MathJaxError,
         case .conversionError(let innerError) = mjError {
        throw LaTeX.ValidationError(message: innerError)
      } else if let error = conversionError {
        throw error
      }
    }
  }

  /// Converts an equation string to MathML.
  ///
  /// Must not be called from `renderQueue`.
  ///
  /// - Parameters:
  ///   - input: The raw equation string (no delimiters).
  ///   - notation: The input notation format.
  ///   - processEscapes: Whether to process escape sequences (TeX only).
  /// - Returns: The MathML string.
  nonisolated static func convertToMathML(
    input: String,
    notation: LaTeX.Notation,
    processEscapes: Bool
  ) throws -> String {
    try renderQueue.sync {
      guard let mathjax = mathjax else {
        throw LaTeX.ValidationError(message: "MathJax is not available")
      }

      let effective = notation == .auto ? sniffNotation(input) : notation
      if effective == .mml { return input }

      let inputOptions = makeInputOptions(notation: effective, processEscapes: processEscapes, errorMode: .error, forNonSVGOutput: true)

      var err: Error?
      let result: String
      switch inputOptions {
      case .tex(let opts):
        result = mathjax.tex2mml(input, inputOptions: opts, error: &err)
      case .am(let opts):
        result = mathjax.am2mml(input, inputOptions: opts, error: &err)
      case .mml:
        return input
      }

      if let mjError = err as? MathJaxError,
         case .conversionError(let innerError) = mjError {
        throw LaTeX.ValidationError(message: innerError)
      } else if let error = err {
        throw error
      }
      return result
    }
  }

  /// Converts an equation string to speech text.
  ///
  /// Must not be called from `renderQueue`.
  ///
  /// - Parameters:
  ///   - input: The raw equation string (no delimiters).
  ///   - notation: The input notation format.
  ///   - processEscapes: Whether to process escape sequences (TeX only).
  ///   - locale: The SRE locale (e.g. "en", "de", "fr").
  ///   - style: The SRE speech style.
  /// - Returns: The speech text.
  nonisolated static func convertToSpeech(
    input: String,
    notation: LaTeX.Notation,
    processEscapes: Bool,
    locale: String,
    style: String
  ) throws -> String {
    try renderQueue.sync {
      guard let mathjax = mathjax else {
        throw LaTeX.ValidationError(message: "MathJax is not available")
      }

      let effective = notation == .auto ? sniffNotation(input) : notation
      let inputOptions = makeInputOptions(notation: effective, processEscapes: processEscapes, errorMode: .error, forNonSVGOutput: true)

      let sreOptions = SREOptions()
      sreOptions.locale = locale
      sreOptions.style = style
      sreOptions.domain = "mathspeak"
      let documentOptions = DocumentOptions()
      documentOptions.sre = sreOptions

      switch inputOptions {
      case .tex(let opts):
        return try mathjax.tex2speech(input, documentOptions: documentOptions, inputOptions: opts)
      case .am(let opts):
        return try mathjax.am2speech(input, documentOptions: documentOptions, inputOptions: opts)
      case .mml:
        return try mathjax.mml2speech(input)
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
  
  /// Packages that require an SVG output jax and cannot be loaded for
  /// non-SVG conversions (e.g. tex2mml, tex2speech).
  private nonisolated static let svgOnlyPackages: Set<String> = ["bussproofs"]

  /// Creates TeX input options safe for non-SVG output (speech).
  private nonisolated static func makeSpeechInputOptions(from opts: TeXInputProcessorOptions) -> TeXInputProcessorOptions {
    let speechOpts = TeXInputProcessorOptions()
    speechOpts.loadPackages = opts.loadPackages.filter { !svgOnlyPackages.contains($0) }
    speechOpts.processEscapes = opts.processEscapes
    speechOpts.inlineMath = opts.inlineMath
    return speechOpts
  }

  /// Creates the appropriate input options for the given notation.
  ///
  /// - Note: `.auto` is resolved to `.latex` here. For actual auto-detection,
  ///   use ``resolveInputOptions(for:notation:processEscapes:errorMode:)``.
  /// - Parameter forNonSVGOutput: When `true`, packages that require an SVG
  ///   output jax (e.g. `bussproofs`) are excluded from the loaded set.
  nonisolated static func makeInputOptions(
    notation: LaTeX.Notation,
    processEscapes: Bool,
    errorMode: LaTeX.ErrorMode,
    display: Bool = true,
    texPackages: Set<LaTeX.TeXPackage>? = nil,
    texAutoload: Bool = true,
    forNonSVGOutput: Bool = false
  ) -> InputOptions {
    switch notation {
    case .latex, .auto:
      let opts = TeXInputProcessorOptions(processEscapes: processEscapes, errorMode: errorMode, packages: texPackages, autoload: texAutoload)
      if forNonSVGOutput {
        opts.loadPackages = opts.loadPackages.filter { !svgOnlyPackages.contains($0) }
      }
      return .tex(opts)
    case .mml:
      return .mml(MMLInputProcessorOptions())
    case .am:
      let opts = AMInputProcessorOptions()
      opts.displaystyle = display
      return .am(opts)
    }
  }

  /// Resolves the input options for a component, taking its notation hint
  /// into account. If the effective notation is `.auto`, the notation is
  /// inferred by sniffing the content.
  nonisolated static func resolveInputOptions(
    for component: Component,
    notation: LaTeX.Notation,
    processEscapes: Bool,
    errorMode: LaTeX.ErrorMode,
    texPackages: Set<LaTeX.TeXPackage>? = nil,
    texAutoload: Bool = true
  ) -> InputOptions {
    let display = !component.type.inline
    let effective = component.notationHint ?? notation
    guard effective == .auto else {
      return makeInputOptions(notation: effective, processEscapes: processEscapes, errorMode: errorMode, display: display, texPackages: texPackages, texAutoload: texAutoload)
    }

    let detected = sniffNotation(component.text)
    return makeInputOptions(notation: detected, processEscapes: processEscapes, errorMode: errorMode, display: display, texPackages: texPackages, texAutoload: texAutoload)
  }

  /// Sniffs the content to guess the notation.
  ///
  /// - MathML: contains `<math` or `<mrow` or similar MathML tags.
  /// - LaTeX: contains `\` commands (e.g. `\frac`, `\sum`, `\begin`).
  /// - AsciiMath: fallback when neither MathML nor LaTeX markers are found.
  private nonisolated static func sniffNotation(_ text: String) -> LaTeX.Notation {
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

    // MathML: look for opening MathML tags
    if trimmed.hasPrefix("<math") || trimmed.contains("<mrow") || trimmed.contains("<mi>")
        || trimmed.contains("<mn>") || trimmed.contains("<mo>") || trimmed.contains("<mfrac")
        || trimmed.contains("<msup") || trimmed.contains("<msub") || trimmed.contains("<msqrt") {
      return .mml
    }

    // LaTeX: look for backslash commands
    if trimmed.contains("\\") {
      return .latex
    }

    // If it's simple like "x^2 + y" it could be either LaTeX or AM.
    // Default to LaTeX since it's the most common.
    return .latex
  }

  /// Renders the view's component blocks.
  ///
  /// - Parameters:
  ///   - blocks: The component blocks.
  ///   - xHeight: The font's x-height.
  ///   - displayScale: The display scale to render at.
  ///   - renderingMode: The image rendering mode.
  ///   - notation: The environment notation.
  ///   - processEscapes: Whether to process escape sequences.
  ///   - errorMode: The error mode.
  /// - Returns: An array of rendered blocks.
  nonisolated func render(
    blocks: [ComponentBlock],
    xHeight: CGFloat,
    displayScale: CGFloat,
    renderingMode: SwiftUI.Image.TemplateRenderingMode,
    notation: LaTeX.Notation,
    processEscapes: Bool,
    errorMode: LaTeX.ErrorMode,
    noCache: Bool = false,
    speechLocale: String = "en",
    speechStyle: LaTeX.SpeechStyle = .default,
    texPackages: Set<LaTeX.TeXPackage>? = nil,
    texAutoload: Bool = true
  ) -> [ComponentBlock] {
    var newBlocks = [ComponentBlock]()
    for block in blocks {
      do {
        let newComponents = try render(
          block.components,
          xHeight: xHeight,
          displayScale: displayScale,
          renderingMode: renderingMode,
          notation: notation,
          processEscapes: processEscapes,
          errorMode: errorMode,
          noCache: noCache,
          speechLocale: speechLocale,
          speechStyle: speechStyle,
          texPackages: texPackages,
          texAutoload: texAutoload)

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

  nonisolated private func render(
    _ components: [Component],
    xHeight: CGFloat,
    displayScale: CGFloat,
    renderingMode: SwiftUI.Image.TemplateRenderingMode,
    notation: LaTeX.Notation,
    processEscapes: Bool,
    errorMode: LaTeX.ErrorMode,
    noCache: Bool,
    speechLocale: String,
    speechStyle: LaTeX.SpeechStyle,
    texPackages: Set<LaTeX.TeXPackage>?,
    texAutoload: Bool
  ) throws -> [Component] {
    var renderedComponents = [Component]()
    for component in components {
      guard component.type.isEquation else {
        renderedComponents.append(component)
        continue
      }

      let inputOptions = Self.resolveInputOptions(
        for: component, notation: notation,
        processEscapes: processEscapes, errorMode: errorMode,
        texPackages: texPackages, texAutoload: texAutoload)

      guard let svg = try getSVG(
        for: component, inputOptions: inputOptions, noCache: noCache,
        speechLocale: speechLocale, speechStyle: speechStyle
      ) else {
        renderedComponents.append(component)
        continue
      }

      guard let image = getImage(for: svg, xHeight: xHeight, displayScale: displayScale, renderingMode: renderingMode, noCache: noCache) else {
        renderedComponents.append(Component(text: component.text, type: component.type, notationHint: component.notationHint, svg: svg))
        continue
      }

      renderedComponents.append(Component(
        text: component.text,
        type: component.type,
        notationHint: component.notationHint,
        svg: svg,
        imageContainer: ImageContainer(
          image: image,
          size: HashableCGSize(svg.size(for: xHeight))
        )
      ))
    }

    return renderedComponents
  }

  /// Gets the component's SVG, if possible.
  ///
  /// The SVG cache is checked first.
  ///
  /// - Parameters:
  ///   - component: The component.
  ///   - inputOptions: The input processor options to use.
  /// - Returns: An SVG.
  nonisolated func getSVG(
    for component: Component,
    inputOptions: InputOptions,
    noCache: Bool = false,
    speechLocale: String = "en",
    speechStyle: LaTeX.SpeechStyle = .default
  ) throws -> SVG? {
    // Create our SVG cache key
    let svgCacheKey = Cache.SVGCacheKey(
      componentText: component.text,
      conversionOptions: component.conversionOptions,
      inputOptions: inputOptions,
      speechLocale: speechLocale,
      speechStyle: speechStyle.rawValue)

    if noCache {
      Cache.shared.removeDataCacheValue(for: svgCacheKey)
    } else if let svgData = Cache.shared.dataCacheValue(for: svgCacheKey) {
      return try SVG(data: svgData)
    }

    guard let mathjax = Self.mathjax else {
      return nil
    }

    // Build SVG output options
    let svgOutputOptions = SVGOutputProcessorOptions()

    // Build document options for speech
    let sreOptions = SREOptions()
    sreOptions.locale = speechLocale
    sreOptions.style = speechStyle.rawValue
    sreOptions.domain = "mathspeak"
    let documentOptions = DocumentOptions()
    documentOptions.sre = sreOptions

    // Perform the conversion
    var conversionError: Error?
    let svgString: String
    let speechText: String?

    switch inputOptions {
    case .tex(let opts):
      svgString = mathjax.tex2svg(
        component.text, styles: false,
        conversionOptions: component.conversionOptions,
        inputOptions: opts, outputOptions: svgOutputOptions,
        error: &conversionError)
      speechText = try? mathjax.tex2speech(
        component.text, conversionOptions: component.conversionOptions,
        documentOptions: documentOptions, inputOptions: Self.makeSpeechInputOptions(from: opts))
    case .mml(let opts):
      svgString = mathjax.mml2svg(
        component.text, styles: false,
        conversionOptions: component.conversionOptions,
        inputOptions: opts, outputOptions: svgOutputOptions,
        error: &conversionError)
      speechText = try? mathjax.mml2speech(component.text)
    case .am(let opts):
      svgString = mathjax.am2svg(
        component.text, styles: false,
        conversionOptions: component.conversionOptions,
        inputOptions: opts, outputOptions: svgOutputOptions,
        error: &conversionError)
      speechText = try? mathjax.am2speech(
        component.text, conversionOptions: component.conversionOptions,
        documentOptions: documentOptions, inputOptions: opts)
    }

    let errorText = try getErrorText(from: conversionError)
    let svg = try SVG(svgString: svgString, errorText: errorText, speechText: speechText)

    if !noCache {
      Cache.shared.setDataCacheValue(try svg.encoded(), for: svgCacheKey)
    }

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
  ///   - noCache: Whether to bypass and evict cached data.
  /// - Returns: The image.
  nonisolated func getImage(
    for svg: SVG,
    xHeight: CGFloat,
    displayScale: CGFloat,
    renderingMode: SwiftUI.Image.TemplateRenderingMode,
    noCache: Bool = false
  ) -> SwiftUI.Image? {
    // Create our cache key
    let cacheKey = Cache.ImageCacheKey(svg: svg, xHeight: xHeight)

    if noCache {
      Cache.shared.removeImageCacheValue(for: cacheKey)
    } else if let image = Cache.shared.imageCacheValue(for: cacheKey) {
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

    // Cache unless disabled
    if !noCache {
      Cache.shared.setImageCacheValue(image, for: cacheKey)
    }

    // Finish up
    return Image(image: image, scale: displayScale)
      .renderingMode(renderingMode)
      .antialiased(true)
      .interpolation(.high)
  }
  
  /// Gets the component's SVG without requiring a `Renderer` instance.
  ///
  /// Must be called on `renderQueue`.
  ///
  /// - Parameters:
  ///   - component: The component.
  ///   - inputOptions: The input processor options.
  /// - Returns: An SVG.
  nonisolated private static func getSVGStatic(
    for component: Component,
    inputOptions: InputOptions,
    svgOutputOptions: SVGOutputProcessorOptions = SVGOutputProcessorOptions(),
    documentOptions: DocumentOptions = DocumentOptions()
  ) throws -> SVG? {
    let svgCacheKey = Cache.SVGCacheKey(
      componentText: component.text,
      conversionOptions: component.conversionOptions,
      inputOptions: inputOptions)

    if let svgData = Cache.shared.dataCacheValue(for: svgCacheKey) {
      return try SVG(data: svgData)
    }

    guard let mathjax = mathjax else {
      return nil
    }

    var conversionError: Error?
    let svgString: String
    let speechText: String?

    switch inputOptions {
    case .tex(let opts):
      svgString = mathjax.tex2svg(
        component.text, styles: false,
        conversionOptions: component.conversionOptions,
        inputOptions: opts, outputOptions: svgOutputOptions,
        error: &conversionError)
      speechText = try? mathjax.tex2speech(
        component.text, conversionOptions: component.conversionOptions,
        documentOptions: documentOptions, inputOptions: makeSpeechInputOptions(from: opts))
    case .mml(let opts):
      svgString = mathjax.mml2svg(
        component.text, styles: false,
        conversionOptions: component.conversionOptions,
        inputOptions: opts, outputOptions: svgOutputOptions,
        error: &conversionError)
      speechText = try? mathjax.mml2speech(component.text)
    case .am(let opts):
      svgString = mathjax.am2svg(
        component.text, styles: false,
        conversionOptions: component.conversionOptions,
        inputOptions: opts, outputOptions: svgOutputOptions,
        error: &conversionError)
      speechText = try? mathjax.am2speech(
        component.text, conversionOptions: component.conversionOptions,
        documentOptions: documentOptions, inputOptions: opts)
    }

    var errorText: String?
    if let mjError = conversionError as? MathJaxError, case .conversionError(let innerError) = mjError {
      errorText = innerError
    } else if let error = conversionError {
      throw error
    }

    let svg = try SVG(svgString: svgString, errorText: errorText, speechText: speechText)
    Cache.shared.setDataCacheValue(try svg.encoded(), for: svgCacheKey)
    return svg
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
  ///   - notation: The environment notation.
  ///   - processEscapes: Whether to process escape sequences.
  ///   - errorMode: The error mode.
  /// - Returns: Whether the blocks are in the renderer's cache.
  nonisolated func blocksExistInCache(_ blocks: [ComponentBlock], xHeight: CGFloat, displayScale: CGFloat, notation: LaTeX.Notation, processEscapes: Bool, errorMode: LaTeX.ErrorMode, texPackages: Set<LaTeX.TeXPackage>? = nil, texAutoload: Bool = true) -> Bool {
    for block in blocks {
      for component in block.components where component.type.isEquation {
        let inputOptions = Self.makeInputOptions(
          notation: component.notationHint ?? notation,
          processEscapes: processEscapes, errorMode: errorMode,
          texPackages: texPackages,
          texAutoload: texAutoload)
        let dataCacheKey = Cache.SVGCacheKey(
          componentText: component.text,
          conversionOptions: component.conversionOptions,
          inputOptions: inputOptions)
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

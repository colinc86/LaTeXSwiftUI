//
//  LaTeX.swift
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

import HTMLEntities
import MathJaxSwift
import SwiftUI

/// A view that can parse and render TeX and LaTeX equations that contain
/// math-mode marcos.
public struct LaTeX: View {
  
  // MARK: Types
  
  /// A closure that takes an equation number and returns a string to display in
  /// the view.
  public typealias FormatEquationNumber = @Sendable (_ n: Int) -> String
  
  /// The input notation format.
  public enum Notation: Hashable, Sendable {

    /// TeX/LaTeX notation.
    case latex

    /// MathML notation.
    case mml

    /// AsciiMath notation.
    case am

    /// Auto-detect the notation by trying each format until one succeeds.
    ///
    /// Notations are tried from most strict to least strict (mml, am,
    /// latex) since the LaTeX parser is very permissive. If the
    /// environment's notation is a concrete value, it is tried first.
    ///
    /// When set as the environment default, every equation without a
    /// notation hint incurs up to three MathJax conversion attempts,
    /// which may impact rendering performance.
    case auto
  }

  /// The view's block rendering mode.
  public enum BlockMode: Hashable, Sendable {
    
    /// Block equations are ignored and always rendered inline.
    case alwaysInline
    
    /// Blocks are rendered as text with newlines.
    case blockText
    
    /// Blocks are rendered as views.
    case blockViews
  }
  
  /// A CSS length value used by MathJax for dimensions.
  public struct CSSLength: Hashable, Sendable, CustomStringConvertible {

    /// The numeric value.
    public var value: Double

    /// The CSS unit.
    public var unit: Unit

    /// CSS length units supported by MathJax.
    public enum Unit: String, Hashable, Sendable {
      /// Font-relative unit (relative to the element's font size).
      case em
      /// Pixels.
      case px
      /// Percentage of the container.
      case percent = "%"
    }

    public var description: String {
      "\(value)\(unit.rawValue)"
    }

    public init(_ value: Double, _ unit: Unit) {
      self.value = value
      self.unit = unit
    }

    /// Creates a length in em units.
    public static func em(_ value: Double) -> CSSLength { CSSLength(value, .em) }

    /// Creates a length in pixels.
    public static func px(_ value: Double) -> CSSLength { CSSLength(value, .px) }

    /// Creates a length as a percentage.
    public static func percent(_ value: Double) -> CSSLength { CSSLength(value, .percent) }
  }

  /// The speech output style for the Speech Rule Engine.
  public enum SpeechStyle: String, Hashable, Sendable {

    /// Default verbosity.
    case `default` = "default"

    /// Brief output.
    case brief = "brief"

    /// Super-brief output.
    case sbrief = "sbrief"
  }

  /// A locale supported by the bundled Speech Rule Engine.
  public enum SpeechLocale: String, Hashable, Sendable {

    /// English.
    case english = "en"

    /// German.
    case german = "de"

    /// French.
    case french = "fr"

    /// Spanish.
    case spanish = "es"
  }

  /// Configuration for automatic line breaking of long equations.
  public struct LineBreaking: Hashable, Sendable {

    /// The maximum width before breaking.
    public var width: CSSLength

    /// Whether to allow breaks in inline equations.
    public var inline: Bool

    /// The vertical spacing between broken lines.
    public var lineleading: CSSLength

    public init(width: CSSLength = .em(100), inline: Bool = false, lineleading: CSSLength = .em(0.2)) {
      self.width = width
      self.inline = inline
      self.lineleading = lineleading
    }

    /// Automatic line breaking with default settings.
    public static let automatic = LineBreaking()
  }

  /// Horizontal alignment for block (display) equations.
  public enum DisplayAlignment: String, Hashable, Sendable {

    /// Align equations to the left.
    case left = "left"

    /// Center equations (default).
    case center = "center"

    /// Align equations to the right.
    case right = "right"

    /// The corresponding SwiftUI alignment.
    internal var swiftUIAlignment: Alignment {
      switch self {
      case .left: return .leading
      case .center: return .center
      case .right: return .trailing
      }
    }
  }

  /// A TeX package available in MathJax.
  public enum TeXPackage: String, CaseIterable, Hashable, Sendable {
    case action, ams, amscd, autoload
    case base, bbox, boldsymbol, braket, bussproofs
    case cancel, cases, centernot, color, colortbl, colorv2, configmacros
    case empheq, enclose, extpfeil
    case gensymb
    case html
    case mathtools, mhchem
    case newcommand, noerrors, noundefined
    case physics
    case require
    case setoptions
    case tagformat, textcomp, textmacros
    case unicode, upgreek
    case verb
  }

  /// The view's equation number mode.
  public enum EquationNumberMode: Sendable {
    
    /// The view should not number named block equations.
    case none
    
    /// The view should number named block equations on the left side.
    case left
    
    /// The view should number named block equations on the right side.
    case right
  }
  
  /// An error thrown when LaTeX validation fails.
  public struct ValidationError: LocalizedError {

    /// The error message from MathJax.
    public let message: String

    public var errorDescription: String? { message }
  }

  /// The view's error mode.
  public enum ErrorMode: Hashable, Sendable {
    
    /// The rendered image should be displayed (if available).
    case rendered
    
    /// The original LaTeX input should be displayed.
    case original
    
    /// The error text should be displayed.
    case error
  }
  
  /// The view's rendering mode.
  public enum ParsingMode: Hashable, Sendable {
    
    /// Render the entire text as the equation.
    case all
    
    /// Find equations in the text and only render the equations.
    case onlyEquations
  }
  
  /// The script type used to determine equation scaling relative to
  /// surrounding text.
  public enum Script: Hashable, Sendable {

    /// Latin and similar scripts — uses font x-height.
    case latin

    /// CJK scripts (Korean, Japanese, Chinese) — uses font cap-height.
    case cjk

    /// Custom multiplier on font x-height.
    case custom(CGFloat)
  }

  /// The view's rendering style.
  public enum RenderingStyle: Hashable, Sendable {
    
    /// The view remains empty until its finished rendering.
    case empty
    
    /// The view displays the input text until it's finished rendering.
    case original

    /// The view displays a redacted version of the view until it's finished
    /// rendering.
    case redactedOriginal

    /// The view displays a progress view until it's finished rendering.
    case progress
    
    /// The view blocks on the main thread until it's finished rendering.
    case wait
  }

  /// The accessibility mode for rendered equation images.
  public enum ImageAccessibilityMode: Hashable, Sendable {

    /// No accessibility label applied (default SwiftUI behavior).
    case none

    /// Use the raw TeX input as the accessibility label.
    case input

    /// Use the Speech Rule Engine to generate natural language (default).
    case sre

    /// Use a custom string as the accessibility label.
    case custom(String)
  }

  // MARK: Static properties
  
  /// The package's shared data cache.
  public static var dataCache: NSCache<NSString, NSData> {
    Cache.shared.dataCache
  }
  
#if os(macOS)
  /// The package's shared image cache.
  public static var imageCache: NSCache<NSString, NSImage> {
    Cache.shared.imageCache
  }
#else
  /// The package's shared image cache.
  public static var imageCache: NSCache<NSString, UIImage> {
    Cache.shared.imageCache
  }
#endif
  
  
  // MARK: Package sets

  /// TeX packages for chemistry notation (e.g. `\ce{H2O}`, `\unit{kg}`).
  public static let chemistryPackages: Set<TeXPackage> = [.base, .ams, .mhchem, .newcommand, .autoload]

  /// TeX packages for physics notation (e.g. `\bra{\psi}`, `\braket`).
  public static let physicsPackages: Set<TeXPackage> = [.base, .ams, .physics, .braket, .newcommand, .autoload]

  /// TeX packages for general math (cancel, boldsymbol, mathtools, etc.).
  public static let mathPackages: Set<TeXPackage> = [.base, .ams, .mathtools, .cancel, .boldsymbol, .newcommand, .autoload]

  /// TeX packages for logic and proof trees.
  public static let logicPackages: Set<TeXPackage> = [.base, .ams, .bussproofs, .newcommand, .autoload]

  // MARK: Public properties

  /// The view's LaTeX input string.
  public let latex: String
  
  // MARK: Environment variables
  
  /// The input notation format.
  @Environment(\.notation) private var notation

  /// Whether caching is disabled.
  @Environment(\.noCache) private var noCache

  /// What to do in the case of an error.
  @Environment(\.errorMode) private var errorMode
  
  /// Whether or not we should unencode the input.
  @Environment(\.unencodeHTML) private var unencodeHTML
  
  /// Should the view parse the entire input string or only equations?
  @Environment(\.parsingMode) private var parsingMode
  
  /// The view's block rendering mode.
  @Environment(\.blockMode) private var blockMode
  
  /// Whether the view should process escapes.
  @Environment(\.processEscapes) private var processEscapes
  
  /// The view's rendering style.
  @Environment(\.renderingStyle) private var renderingStyle
  
  /// The rendering mode to use with the rendered MathJax images.
  @Environment(\.imageRenderingMode) private var imageRenderingMode
  
  /// The animation the view should apply to its rendered images.
  @Environment(\.renderingAnimation) private var renderingAnimation
  
  /// Whether string formatting such as markdown should be ignored or rendered.
  @Environment(\.ignoreStringFormatting) private var ignoreStringFormatting
  
  /// The view's current display scale.
  @Environment(\.displayScale) private var displayScale
  
  /// The view's font.
  @Environment(\.font) private var font
  
  /// The view's UI/NSFont font.
  @Environment(\.platformFont) private var platformFont

  /// The script type for equation scaling.
  @Environment(\.script) private var script

  /// The view's dynamic type size.
  @Environment(\.dynamicTypeSize) private var dynamicTypeSize

  /// Line breaking configuration.
  @Environment(\.lineBreaking) private var lineBreaking

  /// Display alignment for block equations.
  @Environment(\.displayAlignment) private var displayAlignment

  /// Speech locale for accessibility.
  @Environment(\.speechLocale) private var speechLocale

  /// Speech style for accessibility.
  @Environment(\.speechStyle) private var speechStyle

  /// TeX packages to load.
  @Environment(\.texPackages) private var texPackages

  /// Whether TeX autoload is enabled.
  @Environment(\.texAutoload) private var texAutoload

  // MARK: Private properties

  /// The view's renderer.
  @StateObject private var renderer = Renderer()

  /// The view's preload task, if any.
  @State private var preloadTask: Task<(), Never>?

  /// A key that captures all environment values that affect rendering.
  /// When any of these change, the renderer must be reset.
  private var renderingKey: Int {
    var hasher = Hasher()
    hasher.combine(latex)
    hasher.combine(notation)
    hasher.combine(noCache)
    hasher.combine(errorMode)
    hasher.combine(unencodeHTML)
    hasher.combine(parsingMode)
    hasher.combine(processEscapes)
    hasher.combine(imageRenderingMode)
    hasher.combine(displayScale)
    hasher.combine(font)
    hasher.combine(script)
    hasher.combine(dynamicTypeSize)
    hasher.combine(speechLocale)
    hasher.combine(speechStyle)
    hasher.combine(texPackages)
    hasher.combine(texAutoload)
    return hasher.finalize()
  }

  // MARK: Initializers

  /// Initializes a view with a LaTeX input string.
  ///
  /// - Parameter latex: The LaTeX input.
  public init(_ latex: String) {
    self.latex = latex
  }

  // MARK: View body

  public var body: some View {
    VStack(spacing: 0) {
      if renderer.rendered || renderer.syncRendered {
        // If our blocks have been rendered, display them
        bodyWithBlocks(renderer.blocks)
      }
      else if isCached() {
        // If our blocks are cached, display them
        bodyWithBlocks(renderSync())
      }
      else {
        // The view is not rendered nor cached
        switch renderingStyle {
        case .empty, .original, .redactedOriginal, .progress:
          // Render the components asynchronously
          loadingView().task {
            await renderAsync()
          }
        case .wait:
          // Render the components synchronously
          bodyWithBlocks(renderSync())
        }
      }
    }
    .animation(renderingAnimation, value: renderer.rendered)
    .onChange(of: renderingKey) { _ in
      renderer.reset()
    }
    .onDisappear(perform: preloadTask?.cancel)
  }
  
}

// MARK: Public methods

extension LaTeX {
  
  /// Preloads the view's SVG and image data.
  public func preload() {
    preloadTask?.cancel()
    preloadTask = Task { await renderAsync() }
  }
  
#if os(iOS) || os(visionOS)
  public func font(_ font: UIFont) -> some View {
    self
      .platformFont(font)
      .font(Font(font))
  }
#else
  public func font(_ font: NSFont) -> some View {
    self
      .platformFont(font)
      .font(Font(font))
  }
#endif
  
  /// Renders a LaTeX string to an array of platform images.
  ///
  /// Each equation found in the input produces one image. Text between
  /// equations is not rendered.
  ///
  /// - Parameters:
  ///   - latex: The input string.
  ///   - xHeight: The font x-height used to scale equations. If `nil`, the
  ///     body font's x-height is used.
  ///   - displayScale: The display scale factor (default: 2.0).
  ///   - unencodeHTML: Whether to decode HTML entities (default: false).
  ///   - parsingMode: The parsing mode (default: `.onlyEquations`).
  ///   - notation: The input notation format (default: `.latex`).
  ///   - processEscapes: Whether to process escape sequences (default: false).
  ///   - errorMode: The error mode (default: `.rendered`).
  /// - Returns: An array of rendered images, one per equation.
#if os(iOS) || os(visionOS)
  nonisolated public static func renderToImages(
    _ latex: String,
    xHeight: CGFloat? = nil,
    displayScale: CGFloat = 2.0,
    unencodeHTML: Bool = false,
    parsingMode: ParsingMode = .onlyEquations,
    notation: Notation = .latex,
    processEscapes: Bool = false,
    errorMode: ErrorMode = .rendered
  ) -> [UIImage] {
    Renderer.renderToPlatformImages(
      latex: latex,
      unencodeHTML: unencodeHTML,
      parsingMode: parsingMode,
      notation: notation,
      processEscapes: processEscapes,
      errorMode: errorMode,
      xHeight: xHeight ?? Font.body.effectiveXHeight(for: .latin),
      displayScale: displayScale)
  }
#else
  nonisolated public static func renderToImages(
    _ latex: String,
    xHeight: CGFloat? = nil,
    displayScale: CGFloat = 2.0,
    unencodeHTML: Bool = false,
    parsingMode: ParsingMode = .onlyEquations,
    notation: Notation = .latex,
    processEscapes: Bool = false,
    errorMode: ErrorMode = .rendered
  ) -> [NSImage] {
    Renderer.renderToPlatformImages(
      latex: latex,
      unencodeHTML: unencodeHTML,
      parsingMode: parsingMode,
      notation: notation,
      processEscapes: processEscapes,
      errorMode: errorMode,
      xHeight: xHeight ?? Font.body.effectiveXHeight(for: .latin),
      displayScale: displayScale)
  }
#endif

  /// Validates an equation string.
  ///
  /// The input is treated as a raw equation (no delimiters needed). If the
  /// input is invalid, a ``ValidationError`` is thrown containing the error
  /// message from MathJax.
  ///
  /// - Parameters:
  ///   - latex: The equation string.
  ///   - notation: The input notation format (default: `.latex`).
  ///   - processEscapes: Whether to process escape sequences (default: false,
  ///     only applies to `.latex` notation).
  /// - Throws: ``ValidationError`` if the input is not valid.
  nonisolated public static func validate(_ latex: String, notation: Notation = .latex, processEscapes: Bool = false) throws {
    try Renderer.validate(latex: latex, notation: notation, processEscapes: processEscapes)
  }

  /// Returns whether an equation string is valid.
  ///
  /// The input is treated as a raw equation (no delimiters needed).
  ///
  /// - Parameters:
  ///   - latex: The equation string.
  ///   - notation: The input notation format (default: `.latex`).
  ///   - processEscapes: Whether to process escape sequences (default: false,
  ///     only applies to `.latex` notation).
  /// - Returns: `true` if the input is valid, `false` otherwise.
  nonisolated public static func isValid(_ latex: String, notation: Notation = .latex, processEscapes: Bool = false) -> Bool {
    (try? validate(latex, notation: notation, processEscapes: processEscapes)) != nil
  }

  /// Converts an equation string to MathML.
  ///
  /// - Parameters:
  ///   - input: The equation string (no delimiters).
  ///   - notation: The input notation format (default: `.latex`).
  ///   - processEscapes: Whether to process escape sequences (default: false,
  ///     only applies to `.latex` notation).
  /// - Returns: The MathML string.
  nonisolated public static func toMathML(
    _ input: String,
    notation: Notation = .latex,
    processEscapes: Bool = false
  ) throws -> String {
    try Renderer.convertToMathML(input: input, notation: notation, processEscapes: processEscapes)
  }

  /// Converts an equation string to speech text.
  ///
  /// - Parameters:
  ///   - input: The equation string (no delimiters).
  ///   - notation: The input notation format (default: `.latex`).
  ///   - processEscapes: Whether to process escape sequences (default: false,
  ///     only applies to `.latex` notation).
  ///   - locale: The speech locale (default: `"en"`).
  ///   - style: The speech style (default: `.default`).
  /// - Returns: The speech text.
  nonisolated public static func toSpeech(
    _ input: String,
    notation: Notation = .latex,
    processEscapes: Bool = false,
    locale: SpeechLocale = .english,
    style: SpeechStyle = .default
  ) throws -> String {
    try Renderer.convertToSpeech(
      input: input, notation: notation, processEscapes: processEscapes,
      locale: locale.rawValue, style: style.rawValue)
  }

}

// MARK: Private methods

extension LaTeX {

  /// Checks the renderer's caches for the current view.
  ///
  /// If this method returns `true`, then there is no need to do an async
  /// render.
  ///
  /// - Returns: A boolean indicating whether the components to the view are
  ///   cached.
  private func isCached() -> Bool {
    guard !noCache else { return false }
    return renderer.isCached(
      latex: latex,
      unencodeHTML: unencodeHTML,
      parsingMode: parsingMode,
      notation: notation,
      processEscapes: processEscapes,
      errorMode: errorMode,
      texPackages: texPackages,
      texAutoload: texAutoload,
      speechLocale: speechLocale.rawValue,
      speechStyle: speechStyle.rawValue,
      xHeight: (platformFont?.effectiveXHeight(for: script) ?? font?.effectiveXHeight(for: script, sizeCategory: dynamicTypeSize)) ?? Font.body.effectiveXHeight(for: script, sizeCategory: dynamicTypeSize),
      displayScale: displayScale)
  }

  /// Renders the view's components.
  private func renderAsync() async {
    await renderer.render(
      latex: latex,
      unencodeHTML: unencodeHTML,
      parsingMode: parsingMode,
      notation: notation,
      processEscapes: processEscapes,
      errorMode: errorMode,
      noCache: noCache,
      speechLocale: speechLocale.rawValue,
      speechStyle: speechStyle,
      texPackages: texPackages,
      texAutoload: texAutoload,
      xHeight: (platformFont?.effectiveXHeight(for: script) ?? font?.effectiveXHeight(for: script, sizeCategory: dynamicTypeSize)) ?? Font.body.effectiveXHeight(for: script, sizeCategory: dynamicTypeSize),
      displayScale: displayScale,
      renderingMode: imageRenderingMode)
  }

  /// Renders the view's components synchronously.
  ///
  /// - Returns: The rendered components.
  private func renderSync() -> [ComponentBlock] {
    return renderer.renderSync(
      latex: latex,
      unencodeHTML: unencodeHTML,
      parsingMode: parsingMode,
      notation: notation,
      processEscapes: processEscapes,
      errorMode: errorMode,
      noCache: noCache,
      speechLocale: speechLocale.rawValue,
      speechStyle: speechStyle,
      texPackages: texPackages,
      texAutoload: texAutoload,
      xHeight: (platformFont?.effectiveXHeight(for: script) ?? font?.effectiveXHeight(for: script, sizeCategory: dynamicTypeSize)) ?? Font.body.effectiveXHeight(for: script, sizeCategory: dynamicTypeSize),
      displayScale: displayScale,
      renderingMode: imageRenderingMode)
  }
  
  /// Creates the view's body based on its block mode.
  ///
  /// - Parameter blocks: The blocks to display.
  /// - Returns: The view's body.
  @MainActor @ViewBuilder private func bodyWithBlocks(_ blocks: [ComponentBlock]) -> some View {
    switch blockMode {
    case .alwaysInline:
      ComponentBlocksText(blocks: blocks, forceInline: true)
    case .blockText:
      ComponentBlocksText(blocks: blocks)
    case .blockViews:
      ComponentBlocksViews(blocks: blocks)
    }
  }
  
  /// The view to display while its content is rendering.
  ///
  /// - Returns: The view's body.
  @MainActor @ViewBuilder private func loadingView() -> some View {
    switch renderingStyle {
    case .empty:
      Text("")
    case .original:
      Text(latex)
    case .redactedOriginal:
      Text(latex).redacted(reason: .placeholder)
    case .progress:
      ProgressView()
    default:
      EmptyView()
    }
  }
  
}

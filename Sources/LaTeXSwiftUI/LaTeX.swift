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
  public typealias FormatEquationNumber = (_ n: Int) -> String
  
  /// The view's block rendering mode.
  public enum BlockMode {
    
    /// Block equations are ignored and always rendered inline.
    case alwaysInline
    
    /// Blocks are rendered as text with newlines.
    case blockText
    
    /// Blocks are rendered as views.
    case blockViews
  }
  
  public enum EquationNumberMode {
    
    /// The view should not number named block equations.
    case none
    
    /// The view should number named block equations on the left side.
    case left
    
    /// The view should number named block equations on the right side.
    case right
  }
  
  /// The view's error mode.
  public enum ErrorMode {
    
    /// The rendered image should be displayed (if available).
    case rendered
    
    /// The original LaTeX input should be displayed.
    case original
    
    /// The error text should be displayed.
    case error
  }
  
  /// The view's rendering mode.
  public enum ParsingMode {
    
    /// Render the entire text as the equation.
    case all
    
    /// Find equations in the text and only render the equations.
    case onlyEquations
  }
  
  public enum RenderingStyle {
    
    /// The view remains empty until its finished rendering.
    case empty
    
    /// The view displays the input text until its finished rendering.
    case original
    
    /// The view displays a progress view until its finished rendering.
    case progress
    
    /// The view blocks on the main thread until its finished rendering.
    case wait
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
  
  
  // MARK: Public properties
  
  /// The view's LaTeX input string.
  public let latex: String
  
  // MARK: Environment variables
  
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
  
  /// The animation the view should apply to its rendered images.
  @Environment(\.renderingAnimation) private var renderingAnimation
  
  /// The view's current display scale.
  @Environment(\.displayScale) private var displayScale
  
  /// The view's font.
  @Environment(\.font) private var font
  
  // MARK: Private properties
  
  /// The view's renderer.
  @StateObject private var renderer: Renderer
  
  // MARK: Initializers
  
  /// Initializes a view with a LaTeX input string.
  ///
  /// - Parameter latex: The LaTeX input.
  public init(_ latex: String) {
    self.latex = latex
    _renderer = StateObject(wrappedValue: Renderer(latex: latex))
  }
  
  // MARK: View body
  
  public var body: some View {
    VStack(spacing: 0) {
      if renderer.rendered {
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
        case .empty, .original, .progress:
          // Render the components asynchronously
          loadingView().task(renderAsync)
        case .wait:
          // Render the components synchronously
          bodyWithBlocks(renderSync())
        }
      }
    }
    .animation(renderingAnimation, value: renderer.rendered)
    .environmentObject(renderer)
  }
  
}

// MARK: Public methods

extension LaTeX {
  
  /// Preloads the view's SVG and image data.
  public func preload() {
    Task {
      await renderAsync()
    }
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
    renderer.isCached(
      unencodeHTML: unencodeHTML,
      parsingMode: parsingMode,
      processEscapes: processEscapes,
      errorMode: errorMode,
      font: font ?? .body,
      displayScale: displayScale)
  }
  
  /// Renders the view's components.
  @Sendable private func renderAsync() async {
    await renderer.render(
      unencodeHTML: unencodeHTML,
      parsingMode: parsingMode,
      processEscapes: processEscapes,
      errorMode: errorMode,
      font: font ?? .body,
      displayScale: displayScale)
  }
  
  /// Renders the view's components synchronously.
  ///
  /// - Returns: The rendered components.
  private func renderSync() -> [ComponentBlock] {
    renderer.renderSync(
      unencodeHTML: unencodeHTML,
      parsingMode: parsingMode,
      processEscapes: processEscapes,
      errorMode: errorMode,
      font: font ?? .body,
      displayScale: displayScale)
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
  
  @MainActor @ViewBuilder private func loadingView() -> some View {
    switch renderingStyle {
    case .empty:
      Text("")
    case .original:
      Text(latex)
    case .progress:
      ProgressView()
    default:
      EmptyView()
    }
  }
  
}

@available(iOS 16.1, *)
struct LaTeX_Previews: PreviewProvider {
  static var previews: some View {
    VStack {
      LaTeX("Hello, $\\LaTeX$!")
        .font(.largeTitle)
        .foregroundStyle(
          LinearGradient(
            colors: [.red, .orange, .yellow, .green, .blue, .indigo, .purple],
            startPoint: .leading,
            endPoint: .trailing
          )
        )
      
      LaTeX("Hello, $\\LaTeX$!")
        .font(.title)
        .foregroundColor(.red)
      
      LaTeX("Hello, $\\LaTeX$!")
        .font(.title2)
        .foregroundColor(.orange)
      
      LaTeX("Hello, $\\LaTeX$!")
        .font(.title3)
        .foregroundColor(.yellow)
      
      LaTeX("Hello, $\\LaTeX$!")
        .font(.body)
        .foregroundColor(.green)
      
      LaTeX("Hello, $\\LaTeX$!")
        .font(.caption)
        .foregroundColor(.indigo)
      
      LaTeX("Hello, $\\LaTeX$!")
        .font(.caption2)
        .foregroundColor(.purple)
    }
    .fontDesign(.serif)
    .previewLayout(.sizeThatFits)
    .previewDisplayName("Hello, LaTeX!")
    
    VStack {
      LaTeX("Hello, $\\color{blue}\\LaTeX$")
        .imageRenderingMode(.original)
        
      LaTeX("Hello, $\\LaTeX$")
        .imageRenderingMode(.template)
    }
    .previewDisplayName("Image Rendering Mode")
    
    VStack {
      LaTeX("$\\asdf$")
        .errorMode(.error)
      
      LaTeX("$\\asdf$")
        .errorMode(.original)
      
      LaTeX("$\\asdf$")
        .errorMode(.rendered)
    }
    .previewDisplayName("Error Mode")
    
    VStack {
      LaTeX("$x&lt;0$")
        .errorMode(.error)
      
      LaTeX("$x&lt;0$")
        .unencoded()
        .errorMode(.error)
    }
    .previewDisplayName("Unencoded")
    
    VStack {
      LaTeX("$a^2 + b^2 = c^2$")
        .parsingMode(.onlyEquations)
      
      LaTeX("a^2 + b^2 = c^2")
        .parsingMode(.all)
    }
    .previewDisplayName("Parsing Mode")
    
    VStack {
      LaTeX("Equation 1: $$x = 3$$")
        .blockMode(.blockViews)
      
      LaTeX("Equation 1: $$x = 3$$")
        .blockMode(.blockText)
      
      LaTeX("Equation 1: $$x = 3$$")
        .blockMode(.alwaysInline)
    }
    .previewDisplayName("Block Mode")
    
    VStack {
      LaTeX("$$E = mc^2$$")
        .equationNumberMode(.right)
        .equationNumberOffset(10)
        .padding([.bottom])
      
      LaTeX("\\begin{equation} E = mc^2 \\end{equation} \\begin{equation} E = mc^2 \\end{equation}")
        .equationNumberMode(.right)
        .equationNumberOffset(10)
        .equationNumberStart(2)
    }
    .fontDesign(.serif)
    .previewLayout(.sizeThatFits)
    .previewDisplayName("Equation Numbers")
    .formatEquationNumber { n in
      return "~[\(n)]~"
    }
    
    VStack {
      LaTeX("Hello, $\\LaTeX$!")
        .renderingStyle(.wait)
      
      LaTeX("Hello, $\\LaTeX$!")
        .renderingStyle(.empty)
      
      LaTeX("Hello, $\\LaTeX$!")
        .renderingStyle(.original)
        .renderingAnimation(.default)
      
      LaTeX("Hello, $\\LaTeX$!")
        .renderingStyle(.progress)
        .renderingAnimation(.easeIn)
    }
    .previewDisplayName("Rendering Style and Animated")
  }
  
}

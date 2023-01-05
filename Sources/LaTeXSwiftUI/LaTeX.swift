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
import Nuke
import SwiftUI

public struct LaTeX: View {
  
  // MARK: Types
  
  /// The view's block rendering mode.
  public enum BlockMode {
    
    /// Block equations are ignored and always rendered inline.
    case alwaysInline
    
    /// Blocks are rendered as text with newlines.
    case blockText
    
    /// Blocks are rendered as views.
    case blockViews
  }
  
  /// The view's rendering mode.
  public enum ParsingMode {
    
    /// Render the entire text as the equation.
    case all
    
    /// Find equations in the text and only render the equations.
    case onlyEquations
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
  
  /// The package's shared data cache.
  public static var dataCache: DataCache? {
    Renderer.shared.dataCache
  }
  
  /// The package's shared image cache.
  public static var imageCache: ImageCache {
    Renderer.shared.imageCache
  }
  
  // MARK: Public properties
  
  /// The view's LaTeX input string.
  public let latex: String
  
  // MARK: Private properties
  
  /// The rendering mode to use with the rendered MathJax images.
  @Environment(\.imageRenderingMode) private var imageRenderingMode
  
  /// What to do in the case of an error.
  @Environment(\.errorMode) private var errorMode
  
  /// Whether or not we should unencode the input.
  @Environment(\.unencodeHTML) private var unencodeHTML
  
  /// Should the view parse the entire input string or only equations?
  @Environment(\.parsingMode) private var parsingMode
  
  /// The view's block rendering mode.
  @Environment(\.blockMode) private var blockMode
  
  /// The TeX options to pass to MathJax.
  @Environment(\.texOptions) private var texOptions
  
  /// The view's current display scale.
  @Environment(\.displayScale) private var displayScale
  
  /// The view's font.
  @Environment(\.font) private var font
  
  /// The text's line spacing.
  @Environment(\.lineSpacing) private var lineSpacing
  
  /// The blocks to render.
  private var blocks: [ComponentBlock] {
    Renderer.shared.render(
      blocks: Parser.parse(unencodeHTML ? latex.htmlUnescape() : latex, mode: parsingMode),
      font: font ?? .body,
      displayScale: displayScale,
      texOptions: texOptions)
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
    switch blockMode {
    case .alwaysInline:
      blocksAsText(blocks, forceInline: true)
    case .blockText:
      blocksAsText(blocks)
    case .blockViews:
      blocksAsStack(blocks)
    }
  }

}

// MARK: Public methods

extension LaTeX {
  
  /// Preloads the view's components.
  ///
  /// - Note: You must set this method's parameters the same as its environment
  ///   or call it is ineffective and adds additional computational overhead.
  ///
  /// - Returns: A LaTeX view whose components have been preloaded.
  @MainActor public func preload(
    unencodeHTML: Bool = false,
    parsingMode: ParsingMode = .onlyEquations,
    imageRenderingMode: Image.TemplateRenderingMode = .template,
    font: Font = .body,
    displayScale: CGFloat = 1.0,
    texOptions: TeXInputProcessorOptions = TeXInputProcessorOptions(loadPackages: TeXInputProcessorOptions.Packages.all)
  ) -> LaTeX {
    // Render the blocks
    let preloadedBlocks = Renderer.shared.render(
      blocks: Parser.parse(unencodeHTML ? latex.htmlUnescape() : latex, mode: parsingMode),
      font: font,
      displayScale: displayScale,
      texOptions: texOptions)
    
    // Render the images
    for block in preloadedBlocks {
      for component in block.components where component.type.isEquation {
        guard let svg = component.svg else { continue }
        _ = Renderer.shared.convertToImage(
          svg: svg,
          font: font,
          displayScale: displayScale,
          renderingMode: imageRenderingMode)
      }
    }
    return self
  }
  
}

// MARK: Private methods

extension LaTeX {
  
  /// The view's input rendered as a text view.
  ///
  /// - Parameter forceInline: Whether or not block equations should be forced
  ///   as inline.
  /// - Returns: A text view.
  @MainActor
  @discardableResult
  private func blocksAsText(_ blocks: [ComponentBlock], forceInline: Bool = false) -> Text {
    blocks.map { block in
      let text = text(for: block)
      return block.isEquationBlock && !forceInline ?
        Text("\n") + text + Text("\n") :
        text
    }.reduce(Text(""), +)
  }
  
  /// The view's input rendered as a vertical stack of views.
  ///
  /// - Returns: A stack view.
  @MainActor
  @discardableResult
  private func blocksAsStack(_ blocks: [ComponentBlock]) -> some View {
    VStack(alignment: .leading, spacing: lineSpacing + 4) {
      ForEach(blocks, id: \.self) { block in
        if block.isEquationBlock,
           let (image, size) = image(for: block) {
          HorizontalImageScroller(
            image: image,
            height: size.height)
        }
        else {
          text(for: block)
        }
      }
    }
  }
  
  /// Creates the text view for the given block.
  ///
  /// - Parameter block: The block.
  /// - Returns: The text view.
  @MainActor private func text(for block: ComponentBlock) -> Text {
    block.components.enumerated().map { i, component in
      return component.convertToText(
        font: font ?? .body,
        displayScale: displayScale,
        renderingMode: imageRenderingMode,
        errorMode: errorMode,
        blockRenderingMode: blockMode,
        isInEquationBlock: block.isEquationBlock)
    }.reduce(Text(""), +)
  }
  
  /// Creates the image view and its size for the given block.
  ///
  /// If the block isn't an equation block, then this method returns `nil`.
  ///
  /// - Parameter block: The block.
  /// - Returns: The image and its size.
  @MainActor private func image(for block: ComponentBlock) -> (Image, CGSize)? {
    guard block.isEquationBlock,
          let component = block.components.first else {
      return nil
    }
    return component.convertToImage(
      font: font ?? .body,
      displayScale: displayScale,
      renderingMode: imageRenderingMode)
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
  }
  
}

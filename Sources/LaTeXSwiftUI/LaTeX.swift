//
//  LaTeX.swift
//  LaTeXSwiftUI
//
//  Created by Colin Campbell on 11/29/22.
//

import HTMLEntities
import MathJaxSwift
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
  
  // MARK: Public properties
  
  /// The view's LaTeX input string.
  let latex: String
  
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
      asText(forceInline: true)
    case .blockText:
      asText(forceInline: false)
    case .blockViews:
      asStack()
    }
  }

}

extension LaTeX {
  
  /// The view's input rendered as a text view.
  ///
  /// - Parameter forceInline: Whether or not block equations should be forced
  ///   as inline.
  /// - Returns: A text view.
  @MainActor private func asText(forceInline: Bool) -> Text {
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
  @MainActor private func asStack() -> some View {
    VStack(alignment: .leading, spacing: lineSpacing) {
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
        .font(.title)
      
      LaTeX("Hello, $\\LaTeX$!")
        .font(.title2)
        .foregroundColor(.cyan)
      
      LaTeX("Hello, $\\LaTeX$!")
        .font(.title3)
        .foregroundColor(.pink)
    }
    .fontDesign(.serif)
    .previewLayout(.sizeThatFits)
  }
  
}

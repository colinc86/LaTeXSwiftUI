//
//  LaTeX.swift
//  LaTeXSwiftUI
//
//  Created by Colin Campbell on 11/29/22.
//

import HTMLEntities
import MathJaxSwift
import SwiftUI

@available(iOS 16.1, *)
public struct LaTeX: View {
  
  // MARK: Types
  
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
  
  /// The TeX options to pass to MathJax.
  @Environment(\.texOptions) private var texOptions
  
  /// The view's current display scale.
  @Environment(\.displayScale) private var displayScale
  
  /// The current line spacing.
  @Environment(\.lineSpacing) private var lineSpacing
  
  /// The number of lines to display.
  @Environment(\.lineLimit) private var lineLimit
  
  /// The view's font.
  @Environment(\.font) private var font
  
  /// The blocks to render.
  private var blocks: [ComponentBlock] {
    let blocks = Renderer.shared.render(
      blocks: Parser.parse(unencodeHTML ? latex.htmlUnescape() : latex,
        mode: parsingMode),
      font: font ?? .body,
      displayScale: displayScale,
      texOptions: texOptions)
    if lineLimit != nil, let first = blocks.first {
      return [first]
    }
    return blocks
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
    VStack(spacing: lineSpacing) {
      ForEach(blocks) { block in
        text(for: block)
          .multilineTextAlignment(
            block.isEquationBlock ?
            .center :
            .leading)
      }
    }
  }

}

@available(iOS 16.1, *)
extension LaTeX {
  
  /// Creates the text view for the given block.
  ///
  /// - Parameter block: The block.
  /// - Returns: The text view.
  @MainActor private func text(for block: ComponentBlock) -> Text {
    return block.components.enumerated().map { i, component in
      return component.convertToText(
        font: font ?? .body,
        displayScale: displayScale,
        renderingMode: imageRenderingMode,
        errorMode: errorMode,
        isLastComponentInBlock: i == block.components.count - 1)
    }.reduce(Text(""), +)
  }

}

@available(iOS 16.1, *)
struct LaTeX_Previews: PreviewProvider {
  static var previews: some View {
    VStack {
      Group {
        LaTeX(Constants.Previewing.helloLaTeX)
          .font(.largeTitle)
          .overlay(
            LinearGradient(
              colors: [.red, .blue, .green, .yellow],
              startPoint: .leading,
              endPoint: .trailing
            )
            .mask(
              LaTeX(Constants.Previewing.helloLaTeX)
                .font(.largeTitle)
            )
          )
        
        LaTeX(Constants.Previewing.helloLaTeX)
          .font(.title)
          .foregroundColor(.red)
        
        LaTeX(Constants.Previewing.helloLaTeX)
          .font(.title2)
          .foregroundColor(.orange)
        
        LaTeX(Constants.Previewing.helloLaTeX)
          .font(.title3)
          .foregroundColor(.yellow)
        
        LaTeX(Constants.Previewing.helloLaTeX)
          .foregroundColor(.green)
        
        LaTeX(Constants.Previewing.helloLaTeX)
          .font(.footnote)
          .foregroundColor(.blue)
        
        LaTeX(Constants.Previewing.helloLaTeX)
          .font(.caption)
          .foregroundColor(.indigo)
        
        LaTeX(Constants.Previewing.helloLaTeX)
          .font(.caption2)
          .foregroundColor(.purple)
      }
    }
    .fontDesign(.serif)
    .previewDisplayName("Basic Usage")

    ScrollView {
      LaTeX(Constants.Previewing.longLaTeX)
        .unencoded()
    }
    .previewDisplayName("Word Wrapping")

    LaTeX(Constants.Previewing.eulerLaTeX)
      .previewDisplayName("Block Equations")
  }
}

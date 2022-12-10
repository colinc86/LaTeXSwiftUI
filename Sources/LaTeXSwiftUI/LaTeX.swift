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
  
  public enum ErrorMode {
    case rendered
    case original
    case error
  }
  
  // MARK: Public properties
  
  let latex: String
  
  // MARK: Private properties

  @Environment(\.imageRenderingMode) private var imageRenderingMode
  @Environment(\.errorMode) private var errorMode
  @Environment(\.unencodeHTML) private var unencodeHTML
  @Environment(\.parsingMode) private var parsingMode
  @Environment(\.texOptions) private var texOptions
  @Environment(\.displayScale) private var displayScale
  @Environment(\.lineSpacing) private var lineSpacing
  @Environment(\.font) private var font
  
  /// The blocks to render.
  private var blocks: [ComponentBlock] {
    Renderer.shared.render(
      blocks: Parser.parse(unencodeHTML ? latex.htmlUnescape() : latex,
        mode: parsingMode),
      xHeight: xHeight,
      displayScale: displayScale,
      texOptions: texOptions)
  }
  
  /// The current font's x-height.
  private var xHeight: CGFloat {
    _Font.preferredFont(from: font ?? .body).xHeight
  }
  
  // MARK: Initializers
  
  init(_ latex: String) {
    self.latex = latex
  }

  // MARK: View body

  public var body: some View {
    VStack(spacing: lineSpacing) {
      ForEach(blocks) { block in
        text(for: block)
          .multilineTextAlignment(block.isEquationBlock ? .center : .leading)
      }
    }
  }

}

@available(iOS 16.1, *)
extension LaTeX {
  
  /// Creats the text view for the given block.
  ///
  /// - Parameter block: The block.
  /// - Returns: The text view.
  @MainActor private func text(for block: ComponentBlock) -> Text {
    return block.components.enumerated().map { i, component in
      return component.convertToText(
        xHeight: xHeight,
        displayScale: displayScale,
        renderingMode: imageRenderingMode,
        isLastComponentInBlock: i == block.components.count - 1)
    }.reduce(Text(""), +)
  }

}

@available(iOS 16.1, *)
struct LaTeX_Previews: PreviewProvider {
  static var previews: some View {
    VStack {
      LaTeX(Constants.Previewing.helloLaTeX)
        .font(.largeTitle)
      
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

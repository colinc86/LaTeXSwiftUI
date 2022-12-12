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
  
  /// The view's font.
  @Environment(\.font) private var font
  
  /// The blocks to render.
  private var blocks: [ComponentBlock] {
    Renderer.shared.render(
      blocks: Parser.parse(unencodeHTML ? latex.htmlUnescape() : latex,
        mode: parsingMode),
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
    text()
  }

}

@available(iOS 16.1, *)
extension LaTeX {
  
  /// The view's text.
  @MainActor private func text() -> Text {
    blocks.enumerated().map { i, block in
      let text = text(for: block)
      if block.isEquationBlock && i > 0 {
        return Text("\n") + text
      }
      else {
        return text
      }
    }.reduce(Text(""), +)
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
        isLastComponentInBlock: i == block.components.count - 1)
    }.reduce(Text(""), +)
  }

}

@available(iOS 16.1, *)
struct LaTeX_Previews: PreviewProvider {
  static var previews: some View {
    LaTeX(Constants.Previewing.helloLaTeX)
      .font(.largeTitle)
      .fontDesign(.serif)
  }
}

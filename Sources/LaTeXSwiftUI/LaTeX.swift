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
  public enum BlockRenderingMode {
    
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
  @Environment(\.blockRenderingMode) private var blockRenderingMode
  
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

extension LaTeX {
  
  /// The view's text.
  @MainActor private func text() -> Text {
    let blocks = blocks
    return blocks.enumerated().map { i, block in
      text(for: block)
    }.reduce(Text(""), +)
  }
  
  @MainActor private func stack() -> some View {
    EmptyView()
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
        errorMode: errorMode)
    }.reduce(Text(""), +)
  }

}

struct LaTeX_Previews: PreviewProvider {
  static var previews: some View {
    LaTeX("It is proved that if $u_1,\\ldots, u_n$ are vectors in ${\\Bbb R}^k, k\\le n, 1 \\le p < \\infty$ and $$r = ({1\\over k} \\sum ^n_1 |u_i|^p)^{1\\over p}$$ then the volume of the symmetric convex body whose boundary functionals are $\\pm u_1,\\ldots, \\pm u_n$, is bounded from below as $$|\\{ x\\in {\\Bbb R}^k\\colon \\ |\\langle x,u_i \\rangle | \\le 1 \\ \\hbox{for every} \\ i\\}|^{1\\over k} \\ge {1\\over \\sqrt{\\rho}r}.$$ An application to number theory is stated.")
    .background(Color.green)
//    .latexMode(.inline)
    
    VStack {
      LaTeX("Hello, $\\LaTeX$!")
        .font(.title)
      
      LaTeX("Hello, $\\LaTeX$!")
        .font(.title2)
      
      LaTeX("Hello, $\\LaTeX$!")
        .font(.title3)
    }
  }
  
  static func sanitize(_ text: String) -> String {
    text
//      .trimmingCharacters(in: .whitespacesAndNewlines)
      .replacingOccurrences(of: "\n", with: " ")
//      .replacingOccurrences(of: "   ", with: "")
//      .replacingOccurrences(of: "  ", with: " ")
  }
}

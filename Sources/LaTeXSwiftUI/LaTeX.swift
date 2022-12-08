//
//  LaTeX.swift
//  LaTeXSwiftUI
//
//  Created by Colin Campbell on 11/29/22.
//

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
  
  // MARK: Public properties
  
  
  
  // MARK: Private properties

  /// The display scale.
  @Environment(\.displayScale) private var displayScale
  
  /// The view's font.
  @Environment(\.font) private var font
  
  /// The blocks to render.
  @State private var blocks: [ComponentBlock] = []
  
  /// The rendering mode to use with LaTeX rendered images.
  private let renderingMode: Image.TemplateRenderingMode
  
  /// The MathJax TeX input processor options.
  private let options: TexInputProcessorOptions
  
  /// The current font's x-height.
  private var xHeight: CGFloat {
    if let font = font {
      return _Font.preferredFont(from: font).xHeight
    }
    else {
      return _Font.preferredFont(from: .body).xHeight
    }
  }

  // MARK: Initializers

  /// Creates a LaTeX text view.
  ///
  /// - Parameters:
  ///   - text: The text input.
  ///   - parsingMode: Whether or not the entire input, or only equations,
  ///     should be parsed. Only equations are parsed by default.
  ///   - renderingMode: The image rendering mode to use with images rendered
  ///     from LaTeX equations. The default behavior is to use the `template`
  ///     rendering mode so that equations match their surrounding font color,
  ///     but you may use `original` to use the image colors rendered by
  ///     MathJax.
  ///   - options: The MathJax TeX input processor options. The default options
  ///     are used, but you can customize this value to modify the rendering
  ///     subsystem.
  public init(
    _ text: String,
    parsingMode: ParsingMode = .onlyEquations,
    renderingMode: Image.TemplateRenderingMode = .template,
    options: TexInputProcessorOptions = TexInputProcessorOptions()
  ) {
    self.renderingMode = renderingMode
    self.options = options
    _blocks = State(wrappedValue: Renderer.shared.render(
        blocks: Parser.parse(text, mode: parsingMode),
        xHeight: xHeight,
        displayScale: displayScale,
        options: options))
  }

  // MARK: View body

  public var body: some View {
    text()
  }

}

@available(iOS 16.1, *)
extension LaTeX {
  
  @MainActor public func text() -> Text {
    var blockText = Text("")
    for block in blocks {
      blockText = blockText + text(for: block)
    }
    return blockText
  }
  
}

@available(iOS 16.1, *)
extension LaTeX {
  
  /// Creats the text view for the given block.
  ///
  /// - Parameter block: The block.
  /// - Returns: The text view.
  @MainActor private func text(for block: ComponentBlock) -> Text {
    var text = Text("")
    for component in block.components {
      if let svgData = component.svgData,
         let svgGeometry = component.svgGeometry,
         let image = Renderer.shared.convertToImage(
          svgData: svgData,
          geometry: svgGeometry,
          xHeight: xHeight,
          displayScale: displayScale,
          renderingMode: renderingMode) {
        let offset = svgGeometry.verticalAlignment.toPoints(xHeight)
        text = text + Text(image).baselineOffset(offset)
      }
      else {
        text = text + Text(component.text)
      }
    }
    return text
  }

}

@available(iOS 16.1, *)
struct LaTeX_Previews: PreviewProvider {
  static var previews: some View {
    VStack(spacing: 12) {
      LaTeX("This is a title with vertical alignment equal to zero in the SVG geometry object. $X^2$.")
      
      LaTeX("This is a title with vertical alignment equal to zero in the SVG geometry object. $X^2$.")
        .lineLimit(1)
      
      LaTeX("Hello, $\\LaTeX$!")
        .font(.title)
      
      LaTeX("Hello, $\\LaTeX$!")
        .font(.title2)
        .foregroundColor(.red)
      
      LaTeX("Hello, $\\LaTeX$!")
        .font(.title3)
      
      LaTeX("Hello, $\\LaTeX$!")
        .font(.caption2)
      
      LaTeX("""
This is some $\\LaTeX$ with an inline equation and a block equation.
\\begin{equation}
  (x-2)(x+2)=x^2-4
\\end{equation}
""")
    }
    
    VStack(spacing: 12) {
      LaTeX("This is a title with vertical alignment equal to zero in the SVG geometry object. $X^2$.")
      
      LaTeX("This is a title with vertical alignment equal to zero in the SVG geometry object. $X^2$.")
        .lineLimit(1)
      
      LaTeX("Hello, $\\LaTeX$!")
        .font(.title)
      
      LaTeX("Hello, $\\LaTeX$!")
        .font(.title2)
        .foregroundColor(.red)
      
      LaTeX("Hello, $\\LaTeX$!")
        .font(.title3)
      
      LaTeX("Hello, $\\LaTeX$!")
        .font(.caption2)
      
      LaTeX("""
This is some $\\LaTeX$ with an inline equation and a block equation.
\\begin{equation}
  (x-2)(x+2)=x^2-4
\\end{equation}
""")
    }
    .fontDesign(.serif)
  }
}

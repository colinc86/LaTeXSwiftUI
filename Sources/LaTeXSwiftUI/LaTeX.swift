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
  
  // MARK: Private properties

  /// The display scale.
  @Environment(\.displayScale) private var displayScale
  
  /// The view's font.
  @Environment(\.font) private var font
  
  /// The blocks to render.
  @State private var blocks: [ComponentBlock] = []
  
  /// The rendering mode to use with LaTeX rendered images.
  private let renderingMode: Image.TemplateRenderingMode
  
  /// The current font's x-height.
  private var xHeight: CGFloat {
    let fontXHeight: CGFloat
    if let font = font {
      fontXHeight = _Font.preferredFont(from: font).xHeight
    }
    else {
      fontXHeight = _Font.preferredFont(from: .body).xHeight
    }
    return UIFontMetrics.default.scaledValue(for: fontXHeight, compatibleWith: .current)
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
    _ latex: String,
    parsingMode: ParsingMode = .onlyEquations,
    renderingMode: Image.TemplateRenderingMode = .template,
    options: TexInputProcessorOptions = TexInputProcessorOptions()
  ) {
    self.renderingMode = renderingMode
    _blocks = State(wrappedValue: Renderer.shared.render(
      blocks: Parser.parse(latex, mode: parsingMode),
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
  
  /// Creates the text view for the given blocks.
  ///
  /// - Returns: Rendered text.
  @MainActor private func text() -> Text {
    var blockText = Text("")
    for block in blocks {
      blockText = blockText + text(for: block)
    }
    return blockText
  }
  
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
    VStack {
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
        .foregroundColor(.green)
      
      LaTeX("Hello, $\\LaTeX$!")
        .font(.footnote)
        .foregroundColor(.blue)
      
      LaTeX("Hello, $\\LaTeX$!")
        .font(.caption)
        .foregroundColor(.indigo)
      
      LaTeX("Hello, $\\LaTeX$!")
        .font(.caption2)
        .foregroundColor(.purple)
    }
    .fontDesign(.serif)
    .previewDisplayName("Basic Usage")
  }
}

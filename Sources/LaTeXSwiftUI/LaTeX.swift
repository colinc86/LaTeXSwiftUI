//
//  LaTeX.swift
//  LaTeXSwiftUI
//
//  Created by Colin Campbell on 11/29/22.
//

import SwiftUI

@available(iOS 16.1, *)
public struct LaTeX: View {
  
  // MARK: Types
  
  /// The view's rendering mode.
  public enum RenderingMode {
    
    /// Render the entire text as the equation.
    case all
    
    /// Find equations in the text and only render the equations.
    case onlyEquations
  }
  
  // MARK: Private properties
  
  @Environment(\.textColor) private var textColor

  /// The display scale.
  @Environment(\.displayScale) private var displayScale

  /// The view's color scheme.
  @Environment(\.colorScheme) private var colorScheme
  
  /// The view's font.
  @Environment(\.font) private var font
  
  /// The blocks to render.
  @State private var blocks: [ComponentBlock] = []
  
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
  ///   - mode: Whether or not the entire input, or only equations, should be
  ///     parsed and rendered.
  public init(_ text: String, mode: RenderingMode = .onlyEquations) {
    let parsedBlocks = Parser.parse(text, mode: mode)
    let renderedBlocks = Renderer.shared.render(blocks: parsedBlocks, xHeight: xHeight, displayScale: displayScale, color: textColor, colorScheme: colorScheme)
    _blocks = State(wrappedValue: renderedBlocks)
  }

  // MARK: View body

  public var body: some View {
    text(for: blocks)
      .onChange(of: colorScheme, perform: changedColorScheme)
  }

}

@available(iOS 16.1, *)
extension LaTeX {
  
  /// Sets the LaTeX view's text color.
  ///
  /// - Parameter color: The text color.
  /// - Returns: A LaTeX view.
  public func textColor(_ color: Color) -> some View {
    environment(\.textColor, color)
      .foregroundColor(color)
  }
}

@available(iOS 16.1, *)
extension LaTeX {
  
  @MainActor private func text(for blocks: [ComponentBlock]) -> Text {
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
         let image = Renderer.shared.convertToImage(svgData: svgData, geometry: svgGeometry, xHeight: xHeight, displayScale: displayScale) {
#if os(iOS)
        let swiftUIImage = Image(uiImage: image)
#else
        let swiftUIImage = Image(nsImage: image)
#endif
        
        let offset = svgGeometry.verticalAlignment.toPoints(xHeight)
        text = text + Text(swiftUIImage).baselineOffset(offset)
      }
      else {
        text = text + Text(component.text)
      }
    }
    return text
  }

  /// Called when the color scheme changes.
  ///
  /// - Parameter newValue: The new color scheme.
  private func changedColorScheme(to newValue: ColorScheme) {
    withAnimation {
      blocks = Renderer.shared.render(blocks: blocks, xHeight: xHeight, displayScale: displayScale, color: textColor, colorScheme: colorScheme) // render(blocks: blocks, colorScheme: newValue)
    }
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
        .textColor(.red)
        .font(.title2)
      
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
  }
}

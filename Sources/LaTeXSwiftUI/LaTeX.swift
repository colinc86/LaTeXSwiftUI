//
//  LaTeX.swift
//  LaTeXSwiftUI
//
//  Created by Colin Campbell on 11/29/22.
//

import HTMLEntities
import MathJaxSwift
import SwiftUI

private struct ImageRenderingModeKey: EnvironmentKey {
  static let defaultValue: Image.TemplateRenderingMode = .template
}

@available(iOS 16.1, *)
private struct ErrorModeKey: EnvironmentKey {
  static let defaultValue: LaTeX.ErrorMode = .original
}

extension EnvironmentValues {
  var imageRenderingMode: Image.TemplateRenderingMode {
    get { self[ImageRenderingModeKey.self] }
    set { self[ImageRenderingModeKey.self] = newValue }
  }
  
  @available(iOS 16.1, *)
  var errorMode: LaTeX.ErrorMode {
    get { self[ErrorModeKey.self] }
    set { self[ErrorModeKey.self] = newValue }
  }
}

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
  
  // MARK: Private properties

  @Environment(\.imageRenderingMode) private var imageRenderingMode
  @Environment(\.errorMode) private var errorMode
  @Environment(\.displayScale) private var displayScale
  @Environment(\.lineSpacing) private var lineSpacing
  @Environment(\.font) private var font
  
  /// The blocks to render.
  @State private var blocks: [ComponentBlock] = []
  
  /// The current font's x-height.
  private var xHeight: CGFloat {
    _Font.preferredFont(from: font ?? .body).xHeight
  }

  // MARK: Initializers

  /// Creates a LaTeX text view.
  ///
  /// - Parameter text: The text input.
  public init(
    _ latex: String,
    parsingMode: ParsingMode = .onlyEquations,
    unencodeHTML: Bool = false,
    texOptions: TexInputProcessorOptions = TexInputProcessorOptions()
  ) {
    _blocks = State(wrappedValue: Renderer.shared.render(
      blocks: Parser.parse(
        unencodeHTML ? latex.htmlUnescape() : latex,
        mode: parsingMode),
      xHeight: xHeight,
      displayScale: displayScale,
      texOptions: texOptions))
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

extension View {
  
  public func imageRenderingMode(_ renderingMode: Image.TemplateRenderingMode) -> some View {
    environment(\.imageRenderingMode, renderingMode)
  }
  
  @available(iOS 16.1, *)
  public func errorMode(_ mode: LaTeX.ErrorMode) -> some View {
    environment(\.errorMode, mode)
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
      if let svgData = component.svgData,
         let svgGeometry = component.svgGeometry,
         let image = Renderer.shared.convertToImage(
          svgData: svgData,
          geometry: svgGeometry,
          xHeight: xHeight,
          displayScale: displayScale,
          renderingMode: imageRenderingMode) {
        let offset = svgGeometry.verticalAlignment.toPoints(xHeight)
        return Text(image).baselineOffset(offset)
      }
      else if i < block.components.count - 1 {
        return Text(component.originalText)
      }
      else {
        var componentText = component.originalText
        while componentText.hasSuffix("\n") {
          componentText.removeLast(1)
        }
        return Text(componentText)
      }
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

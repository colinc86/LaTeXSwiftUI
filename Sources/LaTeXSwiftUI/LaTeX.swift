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
  @State private var blocks: [ComponentBlock]

  // MARK: Initializers

  /// Creates a LaTeX text view.
  ///
  /// - Parameters:
  ///   - text: The text input.
  ///   - mode: Whether or not the entire input, or only equations, should be
  ///     parsed and rendered.
  public init(_ text: String, mode: RenderingMode = .onlyEquations) {
    _blocks = State(wrappedValue: Parser.parse(text, mode: mode))
  }

  // MARK: View body

  public var body: some View {
    VStack {
      ForEach(blocks) { block in
        text(for: block)
      }
    }
    .onAppear(perform: appeared)
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
  
  /// Called when the view appears.
  private func appeared() {
    render(colorScheme: colorScheme)
  }
  
  /// Creats the text view for the given block.
  ///
  /// - Parameter block: The block.
  /// - Returns: The text view.
  private func text(for block: ComponentBlock) -> Text {
    var text = Text("")
    for component in block.components {
      if let image = component.renderedImage, let offset = component.imageOffset {
#if os(iOS)
        let swiftUIImage = Image(uiImage: image)
#else
        let swiftUIImage = Image(nsImage: image)
#endif
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
    render(colorScheme: newValue)
  }
  
  /// Renders the view's components.
  ///
  /// - Parameter colorScheme: The color scheme to render.
  @Sendable private func render(colorScheme: ColorScheme = .light) {
    Task {
      var newBlocks = [ComponentBlock]()
      for block in blocks {
        do {
          let newComponents = try await Renderer.shared.render(
            block.components,
            xHeight: font == nil ?
              _Font.preferredFont(from: .body).xHeight :
              _Font.preferredFont(from: font!).xHeight,
            displayScale: displayScale,
            textColor: textColor(for: colorScheme))
          
          newBlocks.append(ComponentBlock(components: newComponents))
        }
        catch {
          continue
        }
      }
      
      let newBlocksCopy = newBlocks
      await MainActor.run {
        withAnimation {
          blocks = newBlocksCopy
        }
      }
    }
  }
  
  /// Gets the text color to use.
  ///
  /// - Parameter colorScheme: The current color scheme.
  /// - Returns: A color.
  private func textColor(for colorScheme: ColorScheme) -> Color {
    if let textColor = textColor {
      return textColor
    }
#if os(iOS)
    return colorScheme == .dark ?
    Color(uiColor: .lightText) :
    Color(uiColor: .darkText)
#else
    return Color(nsColor: .textColor)
#endif
  }

}

@available(iOS 16.1, *)
struct LaTeX_Previews: PreviewProvider {
  static var previews: some View {
    VStack(spacing: 12) {
      LaTeX("Probabilistic $X^2$")
        .background(Color.green)
    }
  }
}

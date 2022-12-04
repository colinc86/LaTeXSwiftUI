//
//  LaTeX.swift
//  LaTeXSwiftUI
//
//  Created by Colin Campbell on 11/29/22.
//

import SwiftUI

@available(iOS 16.1, *)
struct LaTeX: View {

  /// The display scale.
  @Environment(\.displayScale) private var displayScale

  /// The view's color scheme.
  @Environment(\.colorScheme) private var colorScheme
  
  @Environment(\.font) private var font

  /// The components to display in the view.
  @State private var components: [LaTeXComponent]

  // MARK: Initializers

  /// Creates a LaTeX text view.
  ///
  /// - Parameters:
  ///   - text: The text input.
  ///   - style: Whether or not the entire input, or only equations, should be
  ///     parsed.
  init(_ text: String, style: LaTeXRenderer.RenderingStyle = .equations) {
    _components = State(wrappedValue: style == .all ? [LaTeXComponent(text: text, type: .inlineEquation)] : LaTeXEquationParser.parse(text))
  }

  // MARK: View body

  var body: some View {
    text
      
      .task(render)
      .onChange(of: colorScheme, perform: changedColorScheme)
  }

  // MARK: Private views

  /// The text to draw in the view.
  var text: Text {
    var text = Text("")
    for component in components {
      if let image = component.renderedImage, let offset = component.imageOffset {
        text = text + Text(Image(uiImage: image)).baselineOffset(offset).fontDesign(.serif)
      }
      else {
        text = text + Text(component.text).fontDesign(.serif)
      }
    }
    return text
  }

}

@available(iOS 16.1, *)
extension LaTeX {

  /// Called when the color scheme changes.
  ///
  /// - Parameter newValue: The new color scheme.
  private func changedColorScheme(to newValue: ColorScheme) {
    render()
  }

  /// Called when the math components should be (re)rendered.
  @Sendable func render() {
    Task {
      do {
        let newComponents = try await LaTeXRenderer.shared.render(
          components,
          xHeight: font == nil ? UIFont.preferredFont(from: .body).xHeight : UIFont.preferredFont(from: font!).xHeight,
          displayScale: displayScale
        )
        
        await MainActor.run {
          withAnimation {
            components = newComponents
          }
        }
      }
      catch {
        
      }
    }
  }

}

@available(iOS 16.1, *)
struct LaTeX_Previews: PreviewProvider {
  static var previews: some View {
    VStack {
      LaTeX("It's working! $\\frac{-b\\pm\\sqrt{b^2-4ac}}{2a}$")
      LaTeX("\\text{It's working! }\\frac{-b\\pm\\sqrt{b^2-4ac}}{2a}", style: .all)
      LaTeX("A lengthy title about $\\zeta(3)$ and how difficult it is to solve in R.")
    }
  }
}

@available(iOS 16.1, *)
extension Text {
  
  init(latex: String, style: LaTeXRenderer.RenderingStyle) {
    let view = LaTeX(latex, style: style)
    view.render()
    self = view.text
  }
  
}

@available(iOS 16.1, *)
struct Text_Previews: PreviewProvider {
  static var previews: some View {
    VStack {
      Text("It's working! $\\frac{-b\\pm\\sqrt{b^2-4ac}}{2a}$")
    }
  }
}

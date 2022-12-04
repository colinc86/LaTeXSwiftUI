//
//  LaTeX.swift
//  LaTeXSwiftUI
//
//  Created by Colin Campbell on 11/29/22.
//

import SwiftUI

@available(iOS 16.1, *)
struct LaTeX: View {
  
  enum RenderingMode {
    
    /// Render the entire text as the equation.
    case all
    
    /// Find equations in the text and only render the equations.
    case onlyEquations
  }
  
  private struct Block: Identifiable {
    let id = UUID()
    let components: [Component]
    var isEquationBlock: Bool {
      components.count == 1 && !components[0].type.inline
    }
  }

  /// The display scale.
  @Environment(\.displayScale) private var displayScale

  /// The view's color scheme.
  @Environment(\.colorScheme) private var colorScheme
  
  @Environment(\.font) private var font
  
  @State private var blocks: [Block]
  
  @State private var id = UUID()

  // MARK: Initializers

  /// Creates a LaTeX text view.
  ///
  /// - Parameters:
  ///   - text: The text input.
  ///   - style: Whether or not the entire input, or only equations, should be
  ///     parsed.
  init(_ text: String, style: RenderingMode = .onlyEquations) {
    let components = style == .all ? [Component(text: text, type: .inlineEquation)] : Parser.parse(text)
    var blocks = [Block]()
    var blockComponents = [Component]()
    for component in components {
      if component.type.inline {
        blockComponents.append(component)
      }
      else {
        blocks.append(Block(components: blockComponents))
        blocks.append(Block(components: [component]))
        blockComponents.removeAll()
      }
    }
    blocks.append(Block(components: blockComponents))
    _blocks = State(wrappedValue: blocks)
  }

  // MARK: View body

  var body: some View {
    content
      .id(id)
      .task(render)
      .onChange(of: colorScheme, perform: changedColorScheme)
  }
  
  @ViewBuilder var content: some View {
    ForEach(blocks) { block in
      text(for: block)
    }
  }

}

@available(iOS 16.1, *)
extension LaTeX {
  
  private func text(for block: Block) -> Text {
    var text = Text("")
    for component in block.components {
      if let image = component.renderedImage, let offset = component.imageOffset {
#if os(iOS)
        text = text + Text(Image(uiImage: image)).baselineOffset(offset)
#else
        text = text + Text(Image(nsImage: image)).baselineOffset(offset)
#endif
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
    render()
  }

  /// Called when the math components should be (re)rendered.
  @Sendable func render() {
    Task {
      var newBlocks = [Block]()
      for block in blocks {
        do {
          let newComponents = try await Renderer.shared.render(
            block.components,
            xHeight: font == nil ? _Font.preferredFont(from: .body).xHeight : _Font.preferredFont(from: font!).xHeight,
            displayScale: displayScale,
            textColor: .primary
          )
          
          newBlocks.append(Block(components: newComponents))
        }
        catch {
          continue
        }
      }
      
      let newBlocksCopy = newBlocks
      await MainActor.run {
        withAnimation {
          blocks = newBlocksCopy
          id = UUID()
        }
      }
    }
  }

}

@available(iOS 16.1, *)
struct LaTeX_Previews: PreviewProvider {
  static var previews: some View {
    VStack {
      LaTeX("""
The quadratic formula is
\\begin{equation}
  \\frac{-b\\pm\\sqrt{b^2-4ac}}{2a}
\\end{equation}
""")
      .font(.body)
      
      Divider()
      
      LaTeX("The quadratic formula is $\\frac{-b\\pm\\sqrt{b^2-4ac}}{2a}$.")
        .font(.title2)
      
      Divider()
      
      LaTeX("The quadratic formula is $\\frac{-b\\pm\\sqrt{b^2-4ac}}{2a}$.")
        .font(.title3)
      
      Divider()
      
      LaTeX("The quadratic formula is $\\frac{-b\\pm\\sqrt{b^2-4ac}}{2a}$.")
        .font(.footnote)
    }
  }
}

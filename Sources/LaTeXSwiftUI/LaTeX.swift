//
//  LaTeX.swift
//  LaTeXSwiftUI
//
//  Created by Colin Campbell on 11/29/22.
//

import SwiftUI

@available(iOS 16.1, *)
struct LaTeX: View {
  
  private struct Block: Identifiable {
    let id = UUID()
    let components: [LaTeXComponent]
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

  // MARK: Initializers

  /// Creates a LaTeX text view.
  ///
  /// - Parameters:
  ///   - text: The text input.
  ///   - style: Whether or not the entire input, or only equations, should be
  ///     parsed.
  init(_ text: String, style: LaTeXRenderer.RenderingStyle = .equations) {
    let components = style == .all ? [LaTeXComponent(text: text, type: .inlineEquation)] : LaTeXEquationParser.parse(text)
    var blocks = [Block]()
    var blockComponents = [LaTeXComponent]()
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
    VStack(alignment: .leading) {
      ForEach(blocks) { block in
        if block.isEquationBlock {
          HStack {
            Spacer()
            text(for: block)
            Spacer()
          }
        }
        else {
          text(for: block)
        }
      }
    }
    .task(render)
    .onChange(of: colorScheme, perform: changedColorScheme)
  }

}

@available(iOS 16.1, *)
extension LaTeX {
  
  private func text(for block: Block) -> Text {
    var text = Text("")
    for component in block.components {
      if let image = component.renderedImage, let offset = component.imageOffset {
        text = text + Text(Image(uiImage: image)).baselineOffset(offset)
      }
      else {
        text = text + Text(component.text)
      }
    }
    return text.fontDesign(.serif)
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
          let newComponents = try await LaTeXRenderer.shared.render(
            block.components,
            xHeight: font == nil ? UIFont.preferredFont(from: .body).xHeight : UIFont.preferredFont(from: font!).xHeight,
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
The quadratic formula is...
\\begin{equation}
  \\frac{-b\\pm\\sqrt{b^2-4ac}}{2a}
\\end{equation}
And this is a multiline block.
""")
      .font(.title)
      LaTeX("The quadratic formula is $\\frac{-b\\pm\\sqrt{b^2-4ac}}{2a}$.")
        .font(.title2)
      LaTeX("The quadratic formula is $\\frac{-b\\pm\\sqrt{b^2-4ac}}{2a}$.")
        .font(.title3)
      LaTeX("The quadratic formula is $\\frac{-b\\pm\\sqrt{b^2-4ac}}{2a}$.")
        .font(.footnote)
    }
  }
}

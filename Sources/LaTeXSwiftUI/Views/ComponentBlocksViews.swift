//
//  ComponentBlocksViews.swift
//  LaTeXSwiftUI
//
//  Copyright (c) 2023 Colin Campbell
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to
//  deal in the Software without restriction, including without limitation the
//  rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
//  IN THE SOFTWARE.
//

import SwiftUI

/// Displays a component block as a text view.
internal struct ComponentBlocksViews: View {
  
  /// The component blocks to display in the view.
  let blocks: [ComponentBlock]
  
  // MARK: Private properties
  
  /// The rendering mode to use with the rendered MathJax images.
  @Environment(\.imageRenderingMode) private var imageRenderingMode
  
  /// What to do in the case of an error.
  @Environment(\.errorMode) private var errorMode
  
  /// The view's font.
  @Environment(\.font) private var font
  
  /// The view's UI/NSFont font.
  @Environment(\.platformFont) private var platformFont
  
  /// The view's current display scale.
  @Environment(\.displayScale) private var displayScale
  
  /// The view's block rendering mode.
  @Environment(\.blockMode) private var blockMode
  
  /// The text's line spacing.
  @Environment(\.lineSpacing) private var lineSpacing
  
  /// Whether string formatting such as markdown should be ignored or rendered.
  @Environment(\.ignoreStringFormatting) private var ignoreStringFormatting

  /// The script type for equation scaling.
  @Environment(\.script) private var script

  /// The view's dynamic type size.
  @Environment(\.dynamicTypeSize) private var dynamicTypeSize

  /// The accessibility mode for equation images.
  @Environment(\.imageAccessibilityMode) private var imageAccessibilityMode

  /// Display alignment for block equations.
  @Environment(\.displayAlignment) private var displayAlignment

  // MARK: View body

  var body: some View {
    VStack(alignment: .leading, spacing: lineSpacing + 4) {
      ForEach(blocks, id: \.self) { block in
        if block.isEquationBlock, let container = block.container, let svg = block.svg {
          HStack(spacing: 0) {
            EquationNumber(blockIndex: blocks.filter({ $0.isEquationBlock }).firstIndex(of: block) ?? 0, side: .left)

            if let errorText = svg.errorText, errorMode != .rendered {
              switch errorMode {
              case .error:
                Text(errorText)
              case .original:
                Text(block.components.first?.originalText ?? "")
              default:
                EmptyView()
              }
            }
            else {
              let scroller = HorizontalImageScroller(
                image: container.image,
                height: container.size.size.height)
              switch imageAccessibilityMode {
              case .none:
                scroller
              case .input:
                scroller.accessibilityLabel(block.components.first?.text ?? "")
              case .sre:
                scroller.accessibilityLabel(svg.speechText ?? block.components.first?.text ?? "")
              case .custom(let label):
                scroller.accessibilityLabel(label)
              }
            }

            EquationNumber(blockIndex: blocks.filter({ $0.isEquationBlock }).firstIndex(of: block) ?? 0, side: .right)
          }
          .frame(maxWidth: .infinity, alignment: displayAlignment.swiftUIAlignment)
        }
        else {
          let textView = block.toText(
            xHeight: (platformFont?.effectiveXHeight(for: script) ?? font?.effectiveXHeight(for: script, sizeCategory: dynamicTypeSize)) ?? Font.body.effectiveXHeight(for: script, sizeCategory: dynamicTypeSize),
            displayScale: displayScale,
            renderingMode: imageRenderingMode,
            errorMode: errorMode,
            blockRenderingMode: blockMode,
            ignoreStringFormatting: ignoreStringFormatting,
            imageAccessibilityMode: imageAccessibilityMode)
          if #available(iOS 18.0, macOS 15.0, *) {
            textView.textRenderer(LineSpacingNormalizer())
          } else {
            textView
          }
        }
      }
    }
  }
  
}

struct ComponentBlocksViewsPreviews: PreviewProvider {
  static var previews: some View {
    ComponentBlocksViews(blocks: [ComponentBlock(components: [
      Component(text: "Hello, World!", type: .text)
    ])])
  }
}

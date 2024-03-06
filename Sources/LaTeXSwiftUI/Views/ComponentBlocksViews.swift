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
  
  /// The view's renderer.
  @EnvironmentObject private var renderer: Renderer
  
  /// The rendering mode to use with the rendered MathJax images.
  @Environment(\.imageRenderingMode) private var imageRenderingMode
  
  /// What to do in the case of an error.
  @Environment(\.errorMode) private var errorMode
  
  /// The view's font.
  @Environment(\.font) private var font
  
  /// The view's current display scale.
  @Environment(\.displayScale) private var displayScale
  
  /// The view's block rendering mode.
  @Environment(\.blockMode) private var blockMode
  
  /// The text's line spacing.
  @Environment(\.lineSpacing) private var lineSpacing
  
  // MARK: View body
  
  var body: some View {
    VStack(alignment: .leading, spacing: lineSpacing + 4) {
      ForEach(blocks, id: \.self) { block in
        if block.isEquationBlock,
           let (image, size, errorText) = renderer.convertToImage(block: block, font: font ?? .body, displayScale: displayScale, renderingMode: imageRenderingMode) {
          HStack(spacing: 0) {
            EquationNumber(blockIndex: blocks.filter({ $0.isEquationBlock }).firstIndex(of: block) ?? 0, side: .left)
            
            if let errorText = errorText, errorMode != .rendered {
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
              HorizontalImageScroller(
                image: image,
                height: size.height)
            }
            
            EquationNumber(blockIndex: blocks.filter({ $0.isEquationBlock }).firstIndex(of: block) ?? 0, side: .right)
          }
        }
        else {
          ComponentBlockText(block: block, renderer: renderer)
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
    .environmentObject(Renderer())
  }
}

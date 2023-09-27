//
//  ComponentBlockText.swift
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
internal struct ComponentBlockText: View {
  
  /// The component blocks to display in the view.
  let block: ComponentBlock
  
  /// The view's renderer.
  let renderer: Renderer
  
  // MARK: Private properties
  
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
  
  // MARK: View body
  
  var body: Text {
    block.components.enumerated().map { i, component in
      return renderer.convertToText(
        component: component,
        font: font ?? .body,
        displayScale: displayScale,
        renderingMode: imageRenderingMode,
        errorMode: errorMode,
        blockRenderingMode: blockMode,
        isInEquationBlock: block.isEquationBlock)
    }.reduce(Text(""), +)
  }
  
}

struct ComponentBlockTextPreviews: PreviewProvider {
  static var previews: some View {
    ComponentBlockText(block: ComponentBlock(components: [
      Component(text: "Hello, World!", type: .text)
    ]), renderer: Renderer())
  }
}

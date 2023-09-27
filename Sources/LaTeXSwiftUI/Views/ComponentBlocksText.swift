//
//  ComponentBlocksText.swift
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
internal struct ComponentBlocksText: View {
  
  /// The component blocks to display in the view.
  let blocks: [ComponentBlock]
  
  /// Whether inline mode should be forced.
  var forceInline: Bool = false
  
  // MARK: Private properties
  
  /// The view's renderer.
  @EnvironmentObject private var renderer: Renderer
  
  // MARK: View body
  
  var body: some View {
    blocks.map { block in
      let text = ComponentBlockText(block: block, renderer: renderer).body
      return block.isEquationBlock && !forceInline ?
      Text("\n") + text + Text("\n") :
      text
    }.reduce(Text(""), +)
  }
  
}

struct ComponentBlocksTextPreviews: PreviewProvider {
  static var previews: some View {
    ComponentBlocksText(blocks: [ComponentBlock(components: [
      Component(text: "Hello, World!", type: .text)
    ])], forceInline: false)
    .environmentObject(Renderer())
  }
}

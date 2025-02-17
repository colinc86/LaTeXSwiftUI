//
//  ComponentBlock.swift
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

import Foundation
import SwiftUI

/// A block of components.
internal struct ComponentBlock: Hashable, Identifiable {
  
  /// The component's identifier.
  ///
  /// Unique to every instance.
  let id = UUID()
  
  /// The block's components.
  let components: [Component]
  
  /// True iff this block has only one component and that component is
  /// not inline.
  var isEquationBlock: Bool {
    components.count == 1 && !components[0].type.inline
  }
  
  /// The SVG of the block's first component, if any.
  var svg: SVG? {
    components.first?.svg
  }
  
  /// The image container of the block's first component, if any.
  var container: ImageContainer? {
    components.first?.imageContainer
  }
  
}

extension ComponentBlock {
  
  /// Converts a component block to a `Text` view.
  ///
  /// - Parameters:
  ///   - font: The font to use.
  ///   - displayScale: The display scale.
  ///   - renderingMode: The rendering mode.
  ///   - errorMode: The error mode.
  ///   - blockRenderingMode: The block rendering mode.
  ///   - ignoreEscapedCharacters: Whether escaped characters should be ignored
  ///     or replaced.
  ///   - ignoreMarkdown: Whether markdown should be ignored or rendered.
  /// - Returns: A `Text` view.
  @MainActor func toText(
    font: Font?,
    displayScale: CGFloat,
    renderingMode: Image.TemplateRenderingMode,
    errorMode: LaTeX.ErrorMode,
    blockRenderingMode: LaTeX.BlockMode,
    ignoreEscapedCharacters: Bool,
    ignoreMarkdown: Bool
  ) -> Text {
    components.enumerated().map { i, component in
      return component.convertToText(
        font: font ?? .body,
        displayScale: displayScale,
        renderingMode: renderingMode,
        errorMode: errorMode,
        blockRenderingMode: blockRenderingMode,
        isInEquationBlock: isEquationBlock,
        ignoreEscapedCharacters: ignoreEscapedCharacters,
        ignoreMarkdown: ignoreMarkdown)
    }.reduce(Text(""), +)
  }
  
}

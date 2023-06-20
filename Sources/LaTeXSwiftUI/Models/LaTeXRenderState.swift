//
//  LaTeXRenderState.swift
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

import MathJaxSwift
import SwiftUI

/// A `LaTeX` view's render state.
internal class LaTeXRenderState: ObservableObject {
  
  /// The view's input string.
  let latex: String
  
  /// Whether or not the view's blocks have been rendered.
  @MainActor @Published var rendered: Bool = false
  
  /// Whether or not the receiver is currently rendering.
  @MainActor @Published var isRendering: Bool = false
  
  /// The rendered blocks.
  @MainActor @Published var blocks: [ComponentBlock] = []
  
  // MARK: Private properties
  
  /// The LaTeX input's parsed blocks.
  private var _parsedBlocks: [ComponentBlock]? = nil
  
  /// Semaphore for thread-safe access to `_parsedBlocks`.
  private var _parsedBlocksSemaphore = DispatchSemaphore(value: 1)
  
  // MARK: Initializers
  
  /// Initializes a render state with an input string.
  ///
  /// - Parameter latex: The view's input string.
  init(latex: String) {
    self.latex = latex
  }
  
}

// MARK: Public methods

extension LaTeXRenderState {
  
  /// Returns whether the view's components are cached.
  ///
  /// - Parameters:
  ///   - unencodeHTML: The `unencodeHTML` environment variable.
  ///   - parsingMode: The `parsingMode` environment variable.
  ///   - processEscapes: The `processEscapes` environment variable.
  ///   - errorMode: The `errorMode` environment variable.
  ///   - font: The `font environment` variable.
  ///   - displayScale: The `displayScale` environment variable.
  ///   - texOptions: The `texOptions` environment variable.
  func isCached(
    unencodeHTML: Bool,
    parsingMode: LaTeX.ParsingMode,
    processEscapes: Bool,
    errorMode: LaTeX.ErrorMode,
    font: Font,
    displayScale: CGFloat
  ) -> Bool {
    let texOptions = TeXInputProcessorOptions(processEscapes: processEscapes, errorMode: errorMode)
    return Renderer.shared.blocksExistInCache(
      parsedBlocks(unencodeHTML: unencodeHTML, parsingMode: parsingMode),
      font: font,
      displayScale: displayScale,
      texOptions: texOptions)
  }
  
  /// Renders the view's components synchronously.
  ///
  /// - Parameters:
  ///   - unencodeHTML: The `unencodeHTML` environment variable.
  ///   - parsingMode: The `parsingMode` environment variable.
  ///   - processEscapes: The `processEscapes` environment variable.
  ///   - errorMode: The `errorMode` environment variable.
  ///   - font: The `font environment` variable.
  ///   - displayScale: The `displayScale` environment variable.
  ///   - texOptions: The `texOptions` environment variable.
  func renderSync(
    unencodeHTML: Bool,
    parsingMode: LaTeX.ParsingMode,
    processEscapes: Bool,
    errorMode: LaTeX.ErrorMode,
    font: Font,
    displayScale: CGFloat
  ) -> [ComponentBlock] {
    let texOptions = TeXInputProcessorOptions(processEscapes: processEscapes, errorMode: errorMode)
    return Renderer.shared.render(
      blocks: parsedBlocks(unencodeHTML: unencodeHTML, parsingMode: parsingMode),
      font: font,
      displayScale: displayScale,
      texOptions: texOptions)
  }
  
  /// Renders the view's components asynchronously.
  ///
  /// - Parameters:
  ///   - unencodeHTML: The `unencodeHTML` environment variable.
  ///   - parsingMode: The `parsingMode` environment variable.
  ///   - processEscapes: The `processEscapes` environment variable.
  ///   - errorMode: The `errorMode` environment variable.
  ///   - font: The `font environment` variable.
  ///   - displayScale: The `displayScale` environment variable.
  ///   - texOptions: The `texOptions` environment variable.
  func render(
    unencodeHTML: Bool,
    parsingMode: LaTeX.ParsingMode,
    processEscapes: Bool,
    errorMode: LaTeX.ErrorMode,
    font: Font,
    displayScale: CGFloat
  ) async {
    let isRen = await isRendering
    let ren = await rendered
    guard !isRen && !ren else {
      return
    }
    await MainActor.run {
      isRendering = true
    }
    
    let texOptions = TeXInputProcessorOptions(processEscapes: processEscapes, errorMode: errorMode)
    let renderedBlocks = await Renderer.shared.render(
      blocks: parsedBlocks(unencodeHTML: unencodeHTML, parsingMode: parsingMode),
      font: font,
      displayScale: displayScale,
      texOptions: texOptions)
    
    await MainActor.run {
      blocks = renderedBlocks
      isRendering = false
      rendered = true
    }
  }
  
}

// MARK: Private methods

extension LaTeXRenderState {
  
  /// Gets the LaTeX input's parsed blocks.
  ///
  /// - Parameters:
  ///   - unencodeHTML: The `unencodeHTML` environment variable.
  ///   - parsingMode: The `parsingMode` environment variable.
  /// - Returns: The parsed blocks.
  private func parsedBlocks(
    unencodeHTML: Bool,
    parsingMode: LaTeX.ParsingMode
  ) -> [ComponentBlock] {
    _parsedBlocksSemaphore.wait()
    defer { _parsedBlocksSemaphore.signal() }
    if let _parsedBlocks {
      return _parsedBlocks
    }
    
    let blocks = Parser.parse(unencodeHTML ? latex.htmlUnescape() : latex, mode: parsingMode)
    _parsedBlocks = blocks
    return blocks
  }
  
}

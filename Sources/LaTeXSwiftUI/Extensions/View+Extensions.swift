//
//  View+Extensions.swift
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

public extension View {
  
  /// Sets the image rendering mode for images rendered by MathJax.
  ///
  /// - Parameter mode: The template rendering mode.
  /// - Returns: A view that applies the template rendering mode to all of the
  ///   rendered images in the view.
  func imageRenderingMode(_ mode: Image.TemplateRenderingMode) -> some View {
    environment(\.imageRenderingMode, mode)
  }
  
  /// Sets the error mode for images rendered by MathJax that contain errors.
  ///
  /// - Parameter mode: The error mode.
  /// - Returns: A view that applies the error mode to its rendered images.
  func errorMode(_ mode: LaTeX.ErrorMode) -> some View {
    environment(\.errorMode, mode)
  }
  
  /// Unencodes HTML input text.
  ///
  /// - Returns: A view that displays unencoded text.
  func unencoded() -> some View {
    environment(\.unencodeHTML, true)
  }
  
  /// Sets the parsing mode to use when parsing LaTeX input.
  ///
  /// - Parameter mode: The LaTeX parsing mode.
  /// - Returns: A view that utilizes the given parsing mode.
  func parsingMode(_ mode: LaTeX.ParsingMode) -> some View {
    environment(\.parsingMode, mode)
  }
  
  /// Sets the equation block mode for block equations rendered in this view.
  ///
  /// - Parameter mode: The block mode.
  /// - Returns: A view that applies the given block mode to block equations.
  func blockMode(_ mode: LaTeX.BlockMode) -> some View {
    environment(\.blockMode, mode)
  }
  
  /// Sets the TeX options for any images rendered with MathJax in this
  /// environment.
  ///
  /// - Parameter options: The TeX input processor options.
  /// - Returns: A view that uses the given TeX input processor options to
  ///   render images in its view.
  func texOptions(_ options: TeXInputProcessorOptions) -> some View {
    environment(\.texOptions, options)
  }
  
}

//
//  EnvironmentValues+Extensions.swift
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

private struct ImageRenderingModeKey: EnvironmentKey {
  static let defaultValue: Image.TemplateRenderingMode = .template
}

private struct ErrorModeKey: EnvironmentKey {
  static let defaultValue: LaTeX.ErrorMode = .original
}

private struct UnencodeHTMLKey: EnvironmentKey {
  static let defaultValue: Bool = false
}

private struct ParsingModeKey: EnvironmentKey {
  static let defaultValue: LaTeX.ParsingMode = .onlyEquations
}

private struct BlockModeKey: EnvironmentKey {
  static let defaultValue: LaTeX.BlockMode = .blockViews
}

private struct TeXInputProcessorOptionsKey: EnvironmentKey {
  static let defaultValue: TeXInputProcessorOptions = TeXInputProcessorOptions(loadPackages: TeXInputProcessorOptions.Packages.all)
}

extension EnvironmentValues {
  
  /// The image rendering mode of this environment.
  var imageRenderingMode: Image.TemplateRenderingMode {
    get { self[ImageRenderingModeKey.self] }
    set { self[ImageRenderingModeKey.self] = newValue }
  }
  
  /// The error mode of this environment.
  var errorMode: LaTeX.ErrorMode {
    get { self[ErrorModeKey.self] }
    set { self[ErrorModeKey.self] = newValue }
  }
  
  /// The unencoded value of this environment.
  var unencodeHTML: Bool {
    get { self[UnencodeHTMLKey.self] }
    set { self[UnencodeHTMLKey.self] = newValue }
  }
  
  /// The parsing mode of this environment.
  var parsingMode: LaTeX.ParsingMode {
    get { self[ParsingModeKey.self] }
    set { self[ParsingModeKey.self] = newValue }
  }
  
  /// The block mode of this environment.
  var blockMode: LaTeX.BlockMode {
    get { self[BlockModeKey.self] }
    set { self[BlockModeKey.self] = newValue }
  }
  
  /// The TeX options of this environment.
  var texOptions: TeXInputProcessorOptions {
    get { self[TeXInputProcessorOptionsKey.self] }
    set { self[TeXInputProcessorOptionsKey.self] = newValue }
  }
  
}

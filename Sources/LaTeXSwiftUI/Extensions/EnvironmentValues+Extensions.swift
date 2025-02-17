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

private struct ProcessEscapesKey: EnvironmentKey {
  static let defaultValue: Bool = false
}

private struct EquationNumberModeKey: EnvironmentKey {
  static let defaultValue: LaTeX.EquationNumberMode = .none
}

private struct EquationNumberStartKey: EnvironmentKey {
  static let defaultValue: Int = 1
}

private struct EquationNumberOffsetKey: EnvironmentKey {
  static let defaultValue: CGFloat = 0.0
}

private struct FormatEquationNumberKey: EnvironmentKey {
  static let defaultValue: LaTeX.FormatEquationNumber = { "(\($0))" }
}

private struct RenderingStyleKey: EnvironmentKey {
  static let defaultValue: LaTeX.RenderingStyle = .wait
}

private struct RenderingAnimationKey: EnvironmentKey {
  static let defaultValue: Animation? = .none
}

private struct IgnoreEscapedCharactersKey: EnvironmentKey {
  static let defaultValue: Bool = false
}

private struct IgnoreMarkdownKey: EnvironmentKey {
  static let defaultValue: Bool = false
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
  
  /// The processEscapes value of this environment.
  var processEscapes: Bool {
    get { self[ProcessEscapesKey.self] }
    set { self[ProcessEscapesKey.self] = newValue }
  }
  
  /// The equation number mode of this environment.
  var equationNumberMode: LaTeX.EquationNumberMode {
    get { self[EquationNumberModeKey.self] }
    set { self[EquationNumberModeKey.self] = newValue }
  }
  
  /// The equation starting number of this environment.
  var equationNumberStart: Int {
    get { self[EquationNumberStartKey.self] }
    set { self[EquationNumberStartKey.self] = newValue }
  }
  
  /// The equation number offset of this environment.
  var equationNumberOffset: CGFloat {
    get { self[EquationNumberOffsetKey.self] }
    set { self[EquationNumberOffsetKey.self] = newValue }
  }
  
  /// The closure used to format equation number before displaying them.
  var formatEquationNumber: LaTeX.FormatEquationNumber {
    get { self[FormatEquationNumberKey.self] }
    set { self[FormatEquationNumberKey.self] = newValue }
  }
  
  /// The rendering style of this environment.
  var renderingStyle: LaTeX.RenderingStyle {
    get { self[RenderingStyleKey.self] }
    set { self[RenderingStyleKey.self] = newValue }
  }
  
  /// Whether or not rendering should be animated.
  var renderingAnimation: Animation? {
    get { self[RenderingAnimationKey.self] }
    set { self[RenderingAnimationKey.self] = newValue }
  }
  
  /// Whether escaped characeters should be ignored or replaced.
  var ignoreEscapedCharacters: Bool {
    get { self[IgnoreEscapedCharactersKey.self] }
    set { self[IgnoreEscapedCharactersKey.self] = newValue }
  }
  
  /// Whether markdown should be ignored or rendered.
  var ignoreMarkdown: Bool {
    get { self[IgnoreMarkdownKey.self] }
    set { self[IgnoreMarkdownKey.self] = newValue }
  }
  
}

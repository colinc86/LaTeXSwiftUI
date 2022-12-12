//
//  EnvironmentValues+Extensions.swift
//  LaTeXSwiftUI
//
//  Created by Colin Campbell on 12/9/22.
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

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

private struct BlockRenderingModeKey: EnvironmentKey {
  static let defaultValue: LaTeX.BlockRenderingMode = .blockViews
}

private struct TeXInputProcessorOptionsKey: EnvironmentKey {
  static let defaultValue: TexInputProcessorOptions = TexInputProcessorOptions(loadPackages: TexInputProcessorOptions.Packages.all)
}

extension EnvironmentValues {
  var imageRenderingMode: Image.TemplateRenderingMode {
    get { self[ImageRenderingModeKey.self] }
    set { self[ImageRenderingModeKey.self] = newValue }
  }
  
  var errorMode: LaTeX.ErrorMode {
    get { self[ErrorModeKey.self] }
    set { self[ErrorModeKey.self] = newValue }
  }
  
  var unencodeHTML: Bool {
    get { self[UnencodeHTMLKey.self] }
    set { self[UnencodeHTMLKey.self] = newValue }
  }
  
  var parsingMode: LaTeX.ParsingMode {
    get { self[ParsingModeKey.self] }
    set { self[ParsingModeKey.self] = newValue }
  }
  
  var blockRenderingMode: LaTeX.BlockRenderingMode {
    get { self[BlockRenderingModeKey.self] }
    set { self[BlockRenderingModeKey.self] = newValue }
  }
  
  var texOptions: TexInputProcessorOptions {
    get { self[TeXInputProcessorOptionsKey.self] }
    set { self[TeXInputProcessorOptionsKey.self] = newValue }
  }
}

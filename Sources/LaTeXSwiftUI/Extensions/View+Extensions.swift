//
//  View+Extensions.swift
//  LaTeXSwiftUI
//
//  Created by Colin Campbell on 12/9/22.
//

import MathJaxSwift
import SwiftUI

extension View {
  
  public func imageRenderingMode(_ mode: Image.TemplateRenderingMode) -> some View {
    environment(\.imageRenderingMode, mode)
  }
  
  public func errorMode(_ mode: LaTeX.ErrorMode) -> some View {
    environment(\.errorMode, mode)
  }
  
  public func unencoded() -> some View {
    environment(\.unencodeHTML, true)
  }
  
  public func parsingMode(_ mode: LaTeX.ParsingMode) -> some View {
    environment(\.parsingMode, mode)
  }
  
  public func blockRenderingMode(_ mode: LaTeX.BlockRenderingMode) -> some View {
    environment(\.blockRenderingMode, mode)
  }
  
  public func texOptions(_ options: TexInputProcessorOptions) -> some View {
    environment(\.texOptions, options)
  }
  
}

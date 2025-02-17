//
//  TeXInputProcessorOptions+Extensions.swift
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
import MathJaxSwift

extension TeXInputProcessorOptions {
  
  /// Initializes a set of options with the correct properties set for rendering
  /// a `LaTeX` view.
  ///
  /// - Parameters:
  ///   - processEscapes: Whether or not escapes should be processed.
  ///   - errorMode: The view's error mode.
  convenience init(processEscapes: Bool, errorMode: LaTeX.ErrorMode) {
    self.init()
    self.processEscapes = processEscapes
    
    var packages = TeXInputProcessorOptions.Packages.all
    if errorMode != .rendered {
      if let noErrorsIndex = packages.firstIndex(of: TeXInputProcessorOptions.Packages.noerrors) {
        packages.remove(at: noErrorsIndex)
      }
      if let noUndefinedIndex = packages.firstIndex(of: TeXInputProcessorOptions.Packages.noundefined) {
        packages.remove(at: noUndefinedIndex)
      }
    }
    loadPackages = packages
    
    // The default inlineMath for MathJax is set to [["\\(", "\\)"]] which isn't
    // useful for this package since we'd rather use dollar signs and reserve
    // parentheses for grouping symbols.
    inlineMath = [["$", "$"]]
  }
  
}

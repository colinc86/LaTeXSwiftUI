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
  
  /// Preloads a `LaTeX` view's SVG and image data.
  ///
  /// This method should be called last in the view's modifier chain (if at
  /// all).
  ///
  /// - Example:
  ///
  /// ```
  /// LaTeX("Hello, $\\LaTeX$!")
  ///   .font(.title)
  ///   .processEscapes()
  ///   .preload()
  /// ```
  ///
  /// - Note: If the receiver isn't a `LaTeX` view, then this method does
  ///   nothing.
  ///
  /// - Returns: A preloaded view.
  func preload() -> some View {
    if let latex = self as? LaTeX {
      latex.preload()
    }
    return self
  }
  
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
  /// - Parameter unencode: Whether the variable should be set to true or false.
  /// - Returns: A view that displays unencoded text.
  func unencoded(_ unencode: Bool = true) -> some View {
    environment(\.unencodeHTML, unencode)
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
  
  /// When set to `true`, you may use `\$` to represent a literal dollar sign,
  /// rather than using it as a math delimiter, and `\\` to represent a literal
  /// backslash (so that you can use `\\\$` to get a literal `\$` or `\\$...$`
  /// to get a backslash just before in-line math).
  ///
  /// When `false`, `\$` will not be altered, and its dollar sign may be
  /// considered part of a math delimiter. Typically this is set to `true` if
  /// you enable the `$ ... $` in-line delimiters, so you can type `\$` and
  /// MathJax will convert it to a regular dollar sign in the rendered document.
  ///
  /// - Reference: [Option Descriptions](https://docs.mathjax.org/en/latest/options/input/tex.html#option-descriptions)
  ///
  /// - Parameter process: Whether escapes should be processed.
  /// - Returns: A view that processes escapes in its text input.
  func processEscapes(_ process: Bool = true) -> some View {
    environment(\.processEscapes, process)
  }
  
  /// Sets whether block view equation numbers should be hidden, displayed on
  /// the left side of an equation, or displayed on the right side.
  ///
  /// - Parameter mode: The equation number mode.
  /// - Returns: A view that numbers its equations.
  func equationNumberMode(_ mode: LaTeX.EquationNumberMode) -> some View {
    environment(\.equationNumberMode, mode)
  }
  
  /// Sets the starting value for equation numbers in this view.
  ///
  /// - Parameter value: The starting value.
  /// - Returns: A view that numbers its equations.
  func equationNumberStart(_ value: Int) -> some View {
    environment(\.equationNumberStart, value)
  }
  
  /// Sets the number's left or right offset.
  ///
  /// - Parameter offset: The offset to set.
  /// - Returns: A view that numbers its equations.
  func equationNumberOffset(_ offset: CGFloat) -> some View {
    environment(\.equationNumberOffset, offset)
  }
  
  /// Sets a block that lets you format the equation number that will be
  /// displayed for named block equations.
  ///
  /// - Parameter perform: The block that will format the equation number.
  /// - Returns: A view that formats its equation numbers.
  func formatEquationNumber(_ perform: @escaping LaTeX.FormatEquationNumber) -> some View {
    environment(\.formatEquationNumber, perform)
  }
  
  /// Sets the view rendering style.
  ///
  /// - Parameter style: The rendering style to use.
  /// - Returns: A view that renders its content.
  func renderingStyle(_ style: LaTeX.RenderingStyle) -> some View {
    environment(\.renderingStyle, style)
  }
  
  /// Sets the animation the view should apply to its rendered images.
  ///
  /// - Parameter animation: The animation.
  /// - Returns: A view that animates its rendered state.
  func renderingAnimation(_ animation: Animation?) -> some View {
    environment(\.renderingAnimation, animation)
  }
  
  /// Sets whether the view should ignore escaped characters or replace them.
  ///
  /// The characeters `&`, `%`, `$`, `#`, `_`, `{`, `}`, `~`, `^`, and `\` are
  /// reserved characters in LaTeX and may appear in a document with an escape
  /// characeter preceeding them.
  ///
  /// Set this environment variable to `true` to render the escape and the
  /// character, or to `false` to have the view replace the escaped characeter
  /// with itself.
  ///
  /// For example
  ///
  /// ```
  /// LaTeX("Bob has \$5.00")
  /// ```
  ///
  /// will display `Bob has $5.00`.
  ///
  /// Whereas
  ///
  /// ```
  /// LaTeX("Bob has $5.00")
  ///   .ignoreEscapedCharacters()
  /// ```
  ///
  /// will display `Bob has \$5.00`.
  ///
  /// - Parameter ignore: Whether to ignore escaped characters.
  /// - Returns: A view that ignores or replaces escaped characters.
  func ignoreEscapedCharacters(_ ignore: Bool = true) -> some View {
    environment(\.ignoreEscapedCharacters, ignore)
  }
  
}

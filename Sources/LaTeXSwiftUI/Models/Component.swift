//
//  Component.swift
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
import SwiftUI

/// A LaTeX component.
internal struct Component: CustomStringConvertible, Equatable, Hashable {
  
  /// A LaTeX component type.
  enum ComponentType: String, Equatable, CustomStringConvertible {
    
    /// A text component.
    case text
    
    /// An inline equation component.
    ///
    /// - Example: `$x^2$`
    case inlineEquation
    
    /// An inline equation component.
    ///
    /// - Example: `\(x^2\)`
    case inlineParenthesesEquation
    
    /// A TeX-style block equation.
    ///
    /// - Example: `$$x^2$$`.
    case texEquation
    
    /// A block equation.
    ///
    /// - Example: `\[x^2\]`
    case blockEquation
    
    /// A named equation component.
    ///
    /// - Example: `\begin{equation}x^2\end{equation}`
    case namedEquation
    
    /// A named equation component.
    ///
    /// - Example: `\begin{equation*}x^2\end{equation*}`
    case namedNoNumberEquation
    
    /// The component's description.
    var description: String {
      rawValue
    }
    
    /// The order we should scan components when parsing.
    static let order: [ComponentType] = [
      .namedNoNumberEquation,
      .namedEquation,
      .blockEquation,
      .texEquation,
      .inlineEquation,
      .inlineParenthesesEquation
    ]
    
    /// The component's left terminator.
    var leftTerminator: String? {
      switch self {
      case .text: return nil
      case .inlineEquation: return "$"
      case .inlineParenthesesEquation: return "\\("
      case .texEquation: return "$$"
      case .blockEquation: return "\\["
      case .namedEquation: return "\\begin{equation}"
      case .namedNoNumberEquation: return "\\begin{equation*}"
      }
    }
    
    /// The component's right terminator.
    var rightTerminator: String? {
      switch self {
      case .text: return nil
      case .inlineEquation: return "$"
      case .inlineParenthesesEquation: return "\\)"
      case .texEquation: return "$$"
      case .blockEquation: return "\\]"
      case .namedEquation: return "\\end{equation}"
      case .namedNoNumberEquation: return "\\end{equation*}"
      }
    }
    
    /// Whether or not this component is inline.
    var inline: Bool {
      switch self {
      case .text, .inlineEquation, .inlineParenthesesEquation: return true
      default: return false
      }
    }
    
    /// True iff the component is not `text`.
    var isEquation: Bool {
      return self != .text
    }
  }
  
  /// The component's inner text.
  let text: String
  
  /// The component's type.
  let type: ComponentType
  
  /// The component's SVG image.
  let svg: SVG?
  
  /// The component's image in its container.
  let imageContainer: ImageContainer?
  
  /// The original input text that created this component.
  var originalText: String {
    "\(type.leftTerminator ?? "")\(text)\(type.rightTerminator ?? "")"
  }
  
  /// The component's original text with newlines trimmed.
  var originalTextTrimmingNewlines: String {
    originalText.trimmingCharacters(in: .newlines)
  }
  
  /// The component's conversion options.
  var conversionOptions: ConversionOptions {
    ConversionOptions(display: !type.inline)
  }
  
  /// The component's description.
  var description: String {
    return "(\(type), \"\(text)\")"
  }
  
  // MARK: Initializers
  
  /// Initializes a component.
  ///
  /// The text passed to the component is stripped of the left and right
  /// terminators defined in the component's type.
  ///
  /// - Parameters:
  ///   - text: The component's text.
  ///   - type: The component's type.
  ///   - svg: The rendered SVG (only applies to equations).
  ///   - imageContainer: The container of the component's image.
  init(text: String, type: ComponentType, svg: SVG? = nil, imageContainer: ImageContainer? = nil) {
    if type.isEquation {
      var text = text
      if let leftTerminator = type.leftTerminator, text.hasPrefix(leftTerminator) {
        text = String(text[text.index(text.startIndex, offsetBy: leftTerminator.count)...])
      }
      if let rightTerminator = type.rightTerminator, text.hasSuffix(rightTerminator) {
        text = String(text[..<text.index(text.endIndex, offsetBy: -rightTerminator.count)])
      }
      self.text = text
    }
    else {
      self.text = text
    }
    
    self.type = type
    self.svg = svg
    self.imageContainer = imageContainer
  }
  
}

extension Component {
  
  /// Converts the component to a `Text` view.
  ///
  /// - Parameters:
  ///   - xHeight: The font's x-height.
  ///   - displayScale: The view's display scale.
  ///   - renderingMode: The image rendering mode.
  ///   - errorMode: The error handling mode.
  ///   - blockRenderingModel: The rendering mode of the block.
  ///   - isInEquationBlock: Whether this block is in an equation block.
  ///   - ignoreStringFormatting: Whether string formatting such as markdown
  ///     should be ignored or rendered.
  /// - Returns: A text view.
  func convertToText(
    xHeight: CGFloat,
    displayScale: CGFloat,
    renderingMode: SwiftUI.Image.TemplateRenderingMode,
    errorMode: LaTeX.ErrorMode,
    blockRenderingMode: LaTeX.BlockMode,
    isInEquationBlock: Bool,
    ignoreStringFormatting: Bool
  ) -> Text {
    // Get the component's text
    let text: Text
    if let svg = svg {
      // Do we have an error?
      if let errorText = svg.errorText, errorMode != .rendered {
        switch errorMode {
        case .original:
          // Use the original tex input
          text = Text(blockRenderingMode == .alwaysInline ? originalTextTrimmingNewlines : originalText)
        case .error:
          // Use the error text
          text = Text(errorText)
        default:
          text = Text("")
        }
      }
      else if let imageContainer {
        let offset = svg.geometry.verticalAlignment.toPoints(xHeight)
        text = Text(imageContainer.image).baselineOffset(blockRenderingMode == .alwaysInline || !isInEquationBlock ? offset : 0)
      }
      else {
        text = Text("")
      }
    }
    else if blockRenderingMode == .alwaysInline {
      text = formattedText(input: originalTextTrimmingNewlines, ignoreStringFormatting: ignoreStringFormatting)
    }
    else {
      text = formattedText(input: originalText, ignoreStringFormatting: ignoreStringFormatting)
    }
    
    return text
  }
  
  /// Formats the input text and returns a text view.
  ///
  /// - Parameters:
  ///   - input: The plaintext to format.
  ///   - ignoreStringFormatting: Whether the method should ignore formatting.
  /// - Returns: A text view.
  func formattedText(input: String, ignoreStringFormatting: Bool) -> Text {
    if ignoreStringFormatting {
      return Text(input)
    }
    else {
      do {
        return Text(try AttributedString(
          markdown: input,
          options: AttributedString.MarkdownParsingOptions(
            allowsExtendedAttributes: true,
            interpretedSyntax: .inlineOnlyPreservingWhitespace,
            failurePolicy: .returnPartiallyParsedIfPossible)))
      }
      catch {
        return Text(input)
      }
    }
  }
  
}

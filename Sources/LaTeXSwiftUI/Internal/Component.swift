//
//  Component.swift
//  LaTeXSwiftUI
//
//  Created by Colin Campbell on 12/3/22.
//

import Foundation
import SwiftUI

/// A block of components.
internal struct ComponentBlock: Hashable, Identifiable {
  
  /// The component's identifier.
  ///
  /// Unique to every instance.
  let id = UUID()
  
  /// The block's components.
  let components: [Component]
  
  /// True iff this block has only one component and that component is
  /// not inline.
  var isEquationBlock: Bool {
    components.count == 1 && !components[0].type.inline
  }
  
}

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
    
    /// The component's description.
    var description: String {
      rawValue
    }
    
    /// The component's left terminator.
    var leftTerminator: String {
      switch self {
      case .text: return ""
      case .inlineEquation: return "$"
      case .texEquation: return "$$"
      case .blockEquation: return "\\]"
      case .namedEquation: return "\\begin{equation}"
      }
    }
    
    /// The component's right terminator.
    var rightTerminator: String {
      switch self {
      case .text: return ""
      case .inlineEquation: return "$"
      case .texEquation: return "$$"
      case .blockEquation: return "\\]"
      case .namedEquation: return "\\end{equation}"
      }
    }
    
    /// Whether or not this component is inline.
    var inline: Bool {
      switch self {
      case .text, .inlineEquation: return true
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
  
  /// The original input text that created this component.
  var originalText: String {
    "\(type.leftTerminator)\(text)\(type.rightTerminator)"
  }
  
  /// The component's text but with all trailing newlines trimmed.
  var originalTextTrimmingNewlines: String {
//    let whitespaceRegex = #"\\s+"#
//    let text = originalText
//    let ranges = text.ranges(of: whitespaceRegex)
//    guard let last = ranges.last, last.upperBound == text.endIndex else {
//      return originalText
//    }
//    return String(text[..<last.lowerBound])
    originalText.trimmingCharacters(in: .newlines)
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
  init(text: String, type: ComponentType, svg: SVG? = nil) {
    if type.isEquation {
      var text = text
      if text.hasPrefix(type.leftTerminator) {
        text = String(text[text.index(text.startIndex, offsetBy: type.leftTerminator.count)...])
      }
      if text.hasSuffix(type.rightTerminator) {
        text = String(text[..<text.index(text.startIndex, offsetBy: text.count - type.rightTerminator.count)])
      }
      self.text = text
    }
    else {
      self.text = text
    }
    
    self.type = type
    self.svg = svg
  }
  
}

// MARK: Methods

extension Component {
  
  /// Converts the component to a `Text` view.
  ///
  /// - Parameters:
  ///   - font: The font to use.
  ///   - displayScale: The view's display scale.
  ///   - renderingMode: The image rendering mode.
  ///   - errorMode: The error handling mode.
  ///   - isLastComponentInBlock: Whether or not this is the last component in
  ///     the block that contains it.
  /// - Returns: A text view.
  @MainActor func convertToText(
    font: Font,
    displayScale: CGFloat,
    renderingMode: Image.TemplateRenderingMode,
    errorMode: LaTeX.ErrorMode,
    blockRenderingMode: LaTeX.BlockRenderingMode,
    isInEquationBlock: Bool
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
      else if let (image, _) = convertToImage(
        font: font,
        displayScale: displayScale,
        renderingMode: renderingMode) {
        let xHeight = _Font.preferredFont(from: font).xHeight
        let offset = svg.geometry.verticalAlignment.toPoints(xHeight)
        text = Text(image).baselineOffset(blockRenderingMode == .alwaysInline || !isInEquationBlock ? offset : 0)
      }
      else {
        text = Text("")
      }
    }
    else if blockRenderingMode == .alwaysInline {
      text = Text(originalTextTrimmingNewlines)
    }
    else {
      text = Text(originalText)
    }
    
    return text
  }
  
  @MainActor func convertToImage(
    font: Font,
    displayScale: CGFloat,
    renderingMode: Image.TemplateRenderingMode
  ) -> (Image, CGSize)? {
    guard let svg = svg else {
      return nil
    }
    return Renderer.shared.convertToImage(
      svg: svg,
      font: font,
      displayScale: displayScale,
      renderingMode: renderingMode)
  }
  
}

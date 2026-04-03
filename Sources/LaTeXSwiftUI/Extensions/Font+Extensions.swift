//
//  Font+Extensions.swift
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
import SwiftUI

#if os(iOS) || os(visionOS)
import UIKit
#else
import Cocoa
#endif



internal extension Font {
  
  /// The font's text style.
  func textStyle() -> _Font.TextStyle? {
    switch self {
    case .largeTitle, .largeTitle.bold(), .largeTitle.italic(), .largeTitle.monospaced(): return .largeTitle
    case .title, .title.bold(), .title.italic(), .title.monospaced(): return .title1
    case .title2, .title2.bold(), .title2.italic(), .title.monospaced(): return .title2
    case .title3, .title3.bold(), .title3.italic(), .title.monospaced(): return .title3
    case .headline, .headline.bold(), .headline.italic(), .headline.monospaced(): return .headline
    case .subheadline, .subheadline.bold(), .subheadline.italic(), .subheadline.monospaced(): return .subheadline
    case .callout, .callout.bold(), .callout.italic(), .callout.monospaced(): return .callout
    case .caption, .caption.bold(), .caption.italic(), .caption.monospaced(): return .caption1
    case .caption2, .caption2.bold(), .caption2.italic(), .caption2.monospaced(): return .caption2
    case .footnote, .footnote.bold(), .footnote.italic(), .footnote.monospaced(): return .footnote
    default: return nil
    }
  }
  
  /// The font's x-height.
  var xHeight: CGFloat {
    _Font.preferredFont(from: self).xHeight
  }

  /// Returns the effective x-height for the given script type.
  func effectiveXHeight(for script: LaTeX.Script, sizeCategory: DynamicTypeSize? = nil) -> CGFloat {
    _Font.preferredFont(from: self, sizeCategory: sizeCategory).effectiveXHeight(for: script)
  }

}

internal extension _Font {

  /// Returns the effective x-height for the given script type.
  func effectiveXHeight(for script: LaTeX.Script) -> CGFloat {
    switch script {
    case .latin:
      return xHeight
    case .cjk:
      return capHeight
    case .custom(let factor):
      return xHeight * factor
    }
  }


  
  /// Returns the preferred font from a SwiftUI font.
  ///
  /// - Parameters:
  ///   - font: The font.
  ///   - sizeCategory: The dynamic type size to use for scaling. If `nil`,
  ///     the current system setting is used.
  /// - Returns: The preferred font.
  class func preferredFont(from font: Font, sizeCategory: DynamicTypeSize? = nil) -> _Font {
    guard let textStyle = font.textStyle() else {
#if os(iOS) || os(visionOS)
      if let sizeCategory {
        let traits = UITraitCollection(preferredContentSizeCategory: UIContentSizeCategory(sizeCategory))
        return _Font.preferredFont(forTextStyle: .body, compatibleWith: traits)
      }
#endif
      return _Font.preferredFont(forTextStyle: .body)
    }
#if os(iOS) || os(visionOS)
    let _font: _Font
    if let sizeCategory {
      let traits = UITraitCollection(preferredContentSizeCategory: UIContentSizeCategory(sizeCategory))
      _font = _Font.preferredFont(forTextStyle: textStyle, compatibleWith: traits)
    } else {
      _font = _Font.preferredFont(forTextStyle: textStyle)
    }
#else
    let _font = _Font.preferredFont(forTextStyle: textStyle)
#endif
    
    switch font {
    case .largeTitle,
        .title,
        .title2,
        .title3,
        .headline,
        .subheadline,
        .callout,
        .caption,
        .caption2,
        .footnote,
        .body:
      return _font
      
    case .largeTitle.bold(),
        .title.bold(),
        .title2.bold(),
        .title3.bold(),
        .headline.bold(),
        .subheadline.bold(),
        .callout.bold(),
        .caption.bold(),
        .caption2.bold(),
        .footnote.bold(),
        .body.bold():
#if os(iOS) || os(visionOS)
      if let descriptor = _font.fontDescriptor.withSymbolicTraits(.traitBold) {
        return _Font(descriptor: descriptor, size: _font.pointSize)
      }
      else {
        return _font
      }
#else
      let descriptor = _font.fontDescriptor.withSymbolicTraits(.bold)
      return _Font(descriptor: descriptor, size: _font.pointSize) ?? _Font.systemFont(ofSize: _font.pointSize)
#endif
      
    case .largeTitle.monospaced(),
        .title.monospaced(),
        .title2.monospaced(),
        .title3.monospaced(),
        .headline.monospaced(),
        .subheadline.monospaced(),
        .callout.monospaced(),
        .caption.monospaced(),
        .caption2.monospaced(),
        .footnote.monospaced(),
        .body.monospaced():
#if os(iOS) || os(visionOS)
      if let descriptor = _font.fontDescriptor.withSymbolicTraits(.traitMonoSpace) {
        return _Font(descriptor: descriptor, size: _font.pointSize)
      }
      else {
        return _font
      }
#else
      let descriptor = _font.fontDescriptor.withSymbolicTraits(.monoSpace)
      return _Font(descriptor: descriptor, size: _font.pointSize) ?? _Font.systemFont(ofSize: _font.pointSize)
#endif
      
    case .largeTitle.italic(),
        .title.italic(),
        .title2.italic(),
        .title3.italic(),
        .headline.italic(),
        .subheadline.italic(),
        .callout.italic(),
        .caption.italic(),
        .caption2.italic(),
        .footnote.italic(),
        .body.italic():
#if os(iOS) || os(visionOS)
      if let descriptor = _font.fontDescriptor.withSymbolicTraits(.traitItalic) {
        return _Font(descriptor: descriptor, size: _font.pointSize)
      }
      else {
        return _font
      }
#else
      let descriptor = _font.fontDescriptor.withSymbolicTraits(.italic)
      return _Font(descriptor: descriptor, size: _font.pointSize) ?? _Font.systemFont(ofSize: _font.pointSize)
#endif
      
    default:
#if os(iOS) || os(visionOS)
      if let sizeCategory {
        let traits = UITraitCollection(preferredContentSizeCategory: UIContentSizeCategory(sizeCategory))
        return _Font.preferredFont(forTextStyle: .body, compatibleWith: traits)
      }
#endif
      return _Font.preferredFont(forTextStyle: .body)
    }
  }

}

#if os(iOS) || os(visionOS)
extension UIContentSizeCategory {

  /// Creates a `UIContentSizeCategory` from a SwiftUI `DynamicTypeSize`.
  init(_ dynamicTypeSize: DynamicTypeSize) {
    switch dynamicTypeSize {
    case .xSmall: self = .extraSmall
    case .small: self = .small
    case .medium: self = .medium
    case .large: self = .large
    case .xLarge: self = .extraLarge
    case .xxLarge: self = .extraExtraLarge
    case .xxxLarge: self = .extraExtraExtraLarge
    case .accessibility1: self = .accessibilityMedium
    case .accessibility2: self = .accessibilityLarge
    case .accessibility3: self = .accessibilityExtraLarge
    case .accessibility4: self = .accessibilityExtraExtraLarge
    case .accessibility5: self = .accessibilityExtraExtraExtraLarge
    @unknown default: self = .large
    }
  }

}
#endif

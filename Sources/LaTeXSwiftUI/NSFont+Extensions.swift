//
//  NSFont+Extensions.swift
//  LaTeXSwiftUI
//
//  Created by Colin Campbell on 12/4/22.
//

import Foundation
import SwiftUI

#if os(macOS)
import Cocoa

internal extension NSFont {
  
  /// Returns the preferred font from a SwiftUI font.
  ///
  /// - Parameter font: The font.
  /// - Returns: The preferred font.
  class func preferredFont(from font: Font) -> NSFont {
    switch font {
    case .largeTitle:
      return NSFont.preferredFont(forTextStyle: .largeTitle)
    case .title:
      return NSFont.preferredFont(forTextStyle: .title1)
    case .title2:
      return NSFont.preferredFont(forTextStyle: .title2)
    case .title3:
      return NSFont.preferredFont(forTextStyle: .title3)
    case .headline:
      return NSFont.preferredFont(forTextStyle: .headline)
    case .subheadline:
      return NSFont.preferredFont(forTextStyle: .subheadline)
    case .callout:
      return NSFont.preferredFont(forTextStyle: .callout)
    case .caption:
      return NSFont.preferredFont(forTextStyle: .caption1)
    case .caption2:
      return NSFont.preferredFont(forTextStyle: .caption2)
    case .footnote:
      return NSFont.preferredFont(forTextStyle: .footnote)
    default:
      return NSFont.preferredFont(forTextStyle: .body)
    }
  }
  
}
#endif

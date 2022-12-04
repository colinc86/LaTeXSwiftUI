//
//  UIFont+Extensions.swift
//  LaTeXSwiftUI
//
//  Created by Colin Campbell on 12/4/22.
//

import Foundation
import SwiftUI

#if os(iOS)
import UIKit

internal extension UIFont {
  
  /// Returns the preferred font from a SwiftUI font.
  ///
  /// - Parameter font: The font.
  /// - Returns: The preferred font.
  class func preferredFont(from font: Font) -> UIFont {
    switch font {
    case .largeTitle:
      return UIFont.preferredFont(forTextStyle: .largeTitle)
    case .title:
      return UIFont.preferredFont(forTextStyle: .title1)
    case .title2:
      return UIFont.preferredFont(forTextStyle: .title2)
    case .title3:
      return UIFont.preferredFont(forTextStyle: .title3)
    case .headline:
      return UIFont.preferredFont(forTextStyle: .headline)
    case .subheadline:
      return UIFont.preferredFont(forTextStyle: .subheadline)
    case .callout:
      return UIFont.preferredFont(forTextStyle: .callout)
    case .caption:
      return UIFont.preferredFont(forTextStyle: .caption1)
    case .caption2:
      return UIFont.preferredFont(forTextStyle: .caption2)
    case .footnote:
      return UIFont.preferredFont(forTextStyle: .footnote)
    default:
      return UIFont.preferredFont(forTextStyle: .body)
    }
  }
  
}
#endif

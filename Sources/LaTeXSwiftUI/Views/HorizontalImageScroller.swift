//
//  HorizontalImageScroller.swift
//  LaTeXSwiftUI
//
//  Created by Colin Campbell on 12/12/22.
//

import SwiftUI

/// A view that contains an image that can be scrolled horizontally.
internal struct HorizontalImageScroller: View {
  
  /// The image to display.
  let image: Image
  
  /// The height of the image.
  let height: CGFloat
  
  /// Whether the scroll view should show its indicators.
  var showsIndicators: Bool = false
  
  // MARK: View body
  
  var body: some View {
    GeometryReader { geometry in
      ScrollView(.horizontal, showsIndicators: showsIndicators) {
        HStack { image }
          .frame(minWidth: geometry.size.width)
      }
    }
    .frame(height: height)
  }
}

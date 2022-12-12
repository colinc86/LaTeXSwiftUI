//
//  HorizontalImageScroller.swift
//  LaTeXSwiftUI
//
//  Created by Colin Campbell on 12/12/22.
//

import SwiftUI

internal struct HorizontalImageScroller: View {
  
  /// The image to display.
  let image: Image
  
  /// The height of the image.
  let height: CGFloat
  
  // MARK: View body
  
  var body: some View {
    GeometryReader { geometry in
      ScrollView(.horizontal, showsIndicators: false) {
        HStack { image }
          .frame(minWidth: geometry.size.width)
      }
    }
    .frame(height: height)
  }
}

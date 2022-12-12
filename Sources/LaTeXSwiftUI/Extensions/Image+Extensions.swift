//
//  Image+Extensions.swift
//  MathJaxSwift
//
//  Created by Colin Campbell on 12/12/22.
//

import SwiftUI

internal extension Image {
  
  init(image: _Image) {
#if os(iOS)
    self.init(uiImage: image)
#else
    self.init(nsImage: image)
#endif
  }
  
}

internal extension _Image {
  
  convenience init?(imageData: Data, scale: CGFloat? = nil) {
#if os(iOS)
    self.init(data: imageData, scale: scale ?? 1)
#else
    self.init(data: imageData)
#endif
  }
  
}

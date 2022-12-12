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

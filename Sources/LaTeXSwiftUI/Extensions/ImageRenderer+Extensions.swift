//
//  ImageRenderer+Extensions.swift
//  MathJaxSwift
//
//  Created by Colin Campbell on 12/12/22.
//

import SwiftUI

internal extension ImageRenderer {
  
  @MainActor var image: _Image? {
#if os(iOS)
    return uiImage
#else
    return nsImage
#endif
  }
  
}

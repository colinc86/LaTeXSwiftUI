//
//  LaTeX_Previews+Fonts.swift
//  LaTeXSwiftUI
//
//  Copyright (c) 2025 Colin Campbell
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

import SwiftUI

#if os(iOS)
import UIKit
typealias PlatformFont = UIFont
#else
import Cocoa
typealias PlatformFont = NSFont
#endif

struct LaTeX_Previews_Fonts: PreviewProvider {
  
  static var previews: some View {
    VStack {
      LaTeX("Hello, $\\LaTeX$!")
        .font(.system(size: 25))
      
      LaTeX("Hello, $\\LaTeX$!")
        .font(PlatformFont.preferredFont(forTextStyle: .title1))
      
      LaTeX("Hello, $\\LaTeX$!")
        .font(PlatformFont.systemFont(ofSize: 36))
      
      LaTeX("Hello, $\\LaTeX$!")
        .font(PlatformFont.boldSystemFont(ofSize: 25))
      
      LaTeX("Hello, $\\LaTeX$!")
        .font(PlatformFont(name: "Avenir", size: 25)!)
    }
    .previewDisplayName("Fonts")
  }
  
}

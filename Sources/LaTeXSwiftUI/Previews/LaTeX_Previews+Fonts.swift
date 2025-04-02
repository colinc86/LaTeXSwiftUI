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

struct LaTeX_Previews_Fonts: PreviewProvider {
    
  static var previews: some View {
    VStack {
      LaTeX("Hello, $\\LaTeX$!")
        .font(.title)
      
      LaTeX("Hello, $\\LaTeX$!")
        .font(UIFont.preferredFont(forTextStyle: .title1))
      
      HStack {
        Text("Test").font(.system(size: 20)).border(Color.blue)
        Text("Test").font(Font(UIFont.systemFont(ofSize: 20))).border(Color.red)
      }
      
      Text("Hello, ").font(.system(size: 30)) +
      Text(Image(systemName: "star")).baselineOffset(-4)
      
      Text("Hello, ").font(UIFont.systemFont(ofSize: 30)) +
      Text(Image(systemName: "star")).baselineOffset(-4)
    }
    .previewDisplayName("AppKit Fonts")
  }
  
}

extension Text {
  public func font(_ font: UIFont) -> Text {
    self.font(Font(font))
  }
}

//
//  LaTeX_Previews+Styles.swift
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

import SwiftUI

struct LaTeX_Previews_Styles: PreviewProvider {
  
  static var tex = (0 ..< 1000).map({ "\\frac{\($0)}{2}" })
  
  static var previews: some View {
    VStack {
      LaTeX("Hello, $\\LaTeX$!")
        .renderingStyle(.wait)
      
      LaTeX("Hello, $\\LaTeX$!")
        .renderingStyle(.empty)
      
      LaTeX("Hello, $\\LaTeX$!")
        .renderingStyle(.original)
        .renderingAnimation(.default)
      
      LaTeX("Hello, $\\LaTeX$!")
        .renderingStyle(.progress)
        .renderingAnimation(.easeIn)
    }
    .previewDisplayName("Rendering Style and Animated")
    
    VStack {
      LaTeX("Hello, $\\LaTeX$!")
        .latexStyle(.automatic)
      
      LaTeX("Hello, $$&lt;\\LaTeX$$!")
        .latexStyle(.standard)
      
      LaTeX("Hello, \\$1.00!")
      
      LaTeX("Hello, \\$1.00!")
        .ignoreEscapedCharacters()
      
      LaTeX("**Hello**, $\\LaTeX$!")
      
      LaTeX("**Hello**, $\\LaTeX$!")
        .ignoreMarkdown()
    }
    .previewDisplayName("View Styles")
    
    List(tex, id: \.self) { input in
      LaTeX(input)
        .parsingMode(.all)
        .renderingStyle(.original)
        .frame(height: 50)
    }
  }
  
}

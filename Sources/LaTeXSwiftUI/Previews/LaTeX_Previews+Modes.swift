//
//  LaTeX_Previews+Modes.swift
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

struct LaTeX_Previews_Modes: PreviewProvider {
  
  static var previews: some View {
    VStack {
      LaTeX("Hello, $\\color{blue}\\LaTeX$")
        .imageRenderingMode(.original)
      
      LaTeX("Hello, $\\LaTeX$")
        .imageRenderingMode(.template)
    }
    .previewDisplayName("Image Rendering Mode")
    
    VStack {
      LaTeX("$\\asdf$")
        .errorMode(.error)
      
      LaTeX("$\\asdf$")
        .errorMode(.original)
      
      LaTeX("$\\asdf$")
        .errorMode(.rendered)
    }
    .previewDisplayName("Error Mode")
    
    VStack {
      LaTeX("$x&lt;0$")
        .errorMode(.error)
      
      LaTeX("$x&lt;0$")
        .unencoded()
        .errorMode(.error)
    }
    .previewDisplayName("Unencoded")
    
    VStack {
      LaTeX("$a^2 + b^2 = c^2$")
        .parsingMode(.onlyEquations)
      
      LaTeX("a^2 + b^2 = c^2")
        .parsingMode(.all)
    }
    .previewDisplayName("Parsing Mode")
    
    VStack {
      LaTeX("Equation 1: $$x = 3$$")
        .blockMode(.blockViews)
      
      LaTeX("Equation 1: $$x = 3$$")
        .blockMode(.blockText)
      
      LaTeX("Equation 1: $$x = 3$$")
        .blockMode(.alwaysInline)
    }
    .previewDisplayName("Block Mode")
  }
  
}

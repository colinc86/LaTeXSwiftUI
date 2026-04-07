//
//  LaTeX_Previews+Notation.swift
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

struct LaTeX_Previews_Notation: PreviewProvider {

  static var previews: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("LaTeX (default)")
        .font(.caption)
      LaTeX("$x^2 + y^2 = z^2$")

      Text("AsciiMath")
        .font(.caption)
      LaTeX("$x^2 + y^2 = z^2$")
        .notation(.am)

      Text("MathML")
        .font(.caption)
      LaTeX("$<math><mrow><msup><mi>x</mi><mn>2</mn></msup><mo>+</mo><msup><mi>y</mi><mn>2</mn></msup><mo>=</mo><msup><mi>z</mi><mn>2</mn></msup></mrow></math>$")
        .notation(.mml)
    }
    .padding()
    .previewDisplayName("Notation Environment Value")

    VStack(alignment: .leading, spacing: 12) {
      Text("Per-equation notation hints")
        .font(.caption)
      LaTeX("LaTeX: [latex]$\\frac{1}{2}$, AsciiMath: [am]$1/2$")

      Text("Hint with block equation")
        .font(.caption)
      LaTeX("[am]$$sum_(i=1)^n i = (n(n+1))/2$$")
    }
    .padding()
    .previewDisplayName("Notation Hints")

    VStack(alignment: .leading, spacing: 12) {
      Text("Auto-detect notation")
        .font(.caption)
      LaTeX("[auto]$x^2 + y^2 = z^2$")

      Text("Auto-detect MathML")
        .font(.caption)
      LaTeX("Hello, [auto]$\\LaTeX$ [auto]$<math><mfrac><mn>1</mn><mn>2</mn></mfrac></math>$")
    }
    .padding()
    .previewDisplayName("Auto Detection")
  }

}

//
//  LaTeX_Previews+LineSpacing.swift
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

/// Demonstrates inline equations with wrapping text.
///
/// On iOS 18+ / macOS 15+, the LineSpacingNormalizer corrects uneven
/// line gaps caused by baseline-offset equation images.
struct LaTeX_Previews_LineSpacing: PreviewProvider {

  static var previews: some View {
    VStack(alignment: .leading, spacing: 24) {
      Text("Inline equation with wrapping text")
        .font(.caption)
      LaTeX("The Pythagorean theorem states that $a^2 + b^2 = c^2$ for any right triangle, which is one of the most fundamental results in Euclidean geometry and has been known since antiquity.")
        .blockMode(.alwaysInline)
    }
    .frame(width: 300)
    .padding()
    .previewDisplayName("Inline Wrapping")

    VStack(alignment: .leading, spacing: 24) {
      Text("Multiple inline equations")
        .font(.caption)
      LaTeX("Given $f(x) = x^2$ and $g(x) = \\sqrt{x}$, the composition $f(g(x)) = x$ holds for all $x \\geq 0$, demonstrating that these functions are inverses of each other on the non-negative reals.")
        .blockMode(.alwaysInline)
    }
    .frame(width: 300)
    .padding()
    .previewDisplayName("Multiple Inline Equations")

    VStack(alignment: .leading, spacing: 24) {
      Text("Tall inline equation")
        .font(.caption)
      LaTeX("This is a sentance before the next one. The integral $\\int_0^\\infty e^{-x^2} dx = \\frac{\\sqrt{\\pi}}{2}$ is known as the Gaussian integral and appears frequently in probability theory and statistical mechanics.")
        .blockMode(.alwaysInline)
    }
    .frame(width: 300)
    .padding()
    .previewDisplayName("Tall Inline Equation")
  }

}

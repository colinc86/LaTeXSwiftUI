//
//  LaTeX_Previews+Arrays.swift
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

struct LaTeX_Previews_Arrays: PreviewProvider {

  static var previews: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("Vertical lines only")
        .font(.caption)
      LaTeX("$$\\begin{array}{|c|c|c|} a & b & c \\\\ d & e & f \\end{array}$$")
    }
    .padding()
    .previewDisplayName("Vertical Lines")

    VStack(alignment: .leading, spacing: 16) {
      Text("Horizontal and vertical lines")
        .font(.caption)
      LaTeX("$$\\begin{array}{|c|c|c|} \\hline a & b & c \\\\ \\hline d & e & f \\\\ \\hline \\end{array}$$")
    }
    .padding()
    .previewDisplayName("Full Grid")

    VStack(alignment: .leading, spacing: 16) {
      Text("Top hline only")
        .font(.caption)
      LaTeX("$$\\begin{array}{|c|c|c|} \\hline a & b & c \\\\ d & e & f \\end{array}$$")
    }
    .padding()
    .previewDisplayName("Top Hline")

    VStack(alignment: .leading, spacing: 16) {
      Text("Matrix (no lines)")
        .font(.caption)
      LaTeX("$$\\begin{pmatrix} 1 & 2 \\\\ 3 & 4 \\end{pmatrix}$$")

      Text("Determinant")
        .font(.caption)
      LaTeX("$$\\begin{vmatrix} a & b \\\\ c & d \\end{vmatrix} = ad - bc$$")
    }
    .padding()
    .previewDisplayName("Matrices")

    VStack(alignment: .leading, spacing: 16) {
      Text("Cases")
        .font(.caption)
      LaTeX("$$f(x) = \\begin{cases} x^2 & \\text{if } x \\geq 0 \\\\ -x & \\text{if } x < 0 \\end{cases}$$")
    }
    .padding()
    .previewDisplayName("Cases")
  }

}

//
//  LaTeX_Previews+Script.swift
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

struct LaTeX_Previews_Script: PreviewProvider {

  static var previews: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("Default (.latin)")
        .font(.caption)
      LaTeX("The equation $x^2 + y^2 = z^2$ is well known.")

      Text(".cjk")
        .font(.caption)
      LaTeX("방정식 $x^2 + y^2 = z^2$ 은 잘 알려져 있습니다.")
        .script(.cjk)

      Text(".latin (for comparison with CJK text)")
        .font(.caption)
      LaTeX("방정식 $x^2 + y^2 = z^2$ 은 잘 알려져 있습니다.")
        .script(.latin)
    }
    .padding()
    .previewDisplayName("Script Mode")

    VStack(alignment: .leading, spacing: 16) {
      Text("Japanese with .cjk")
        .font(.caption)
      LaTeX("方程式 $E = mc^2$ は有名です。")
        .script(.cjk)

      Text("Chinese with .cjk")
        .font(.caption)
      LaTeX("方程 $\\int_0^1 x^2 dx = \\frac{1}{3}$ 很重要。")
        .script(.cjk)

      Text("Custom scale factor (1.3)")
        .font(.caption)
      LaTeX("The equation $x^2 + y^2 = z^2$ scaled up.")
        .script(.custom(1.3))
    }
    .padding()
    .previewDisplayName("Script Mode - Languages")
  }

}

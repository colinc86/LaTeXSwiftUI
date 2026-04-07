//
//  LaTeX_Previews+Features.swift
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

struct LaTeX_Previews_Features: PreviewProvider {

  static var previews: some View {
    // MARK: toMathML
    VStack(alignment: .leading, spacing: 8) {
      LaTeX("$\\frac{a}{b}$")

      Text("MathML output:")
        .font(.caption)
      Text((try? LaTeX.toMathML("\\frac{a}{b}")) ?? "error")
        .font(.system(.caption, design: .monospaced))
        .lineLimit(3)
    }
    .padding()
    .previewDisplayName("toMathML")

    // MARK: toSpeech
    VStack(alignment: .leading, spacing: 8) {
      LaTeX("$\\frac{a}{b} + \\sqrt{c}$")

      Text("Speech (default):")
        .font(.caption)
      Text((try? LaTeX.toSpeech("\\frac{a}{b} + \\sqrt{c}")) ?? "error")
        .font(.caption2)

      Text("Speech (brief):")
        .font(.caption)
      Text((try? LaTeX.toSpeech("\\frac{a}{b} + \\sqrt{c}", style: .brief)) ?? "error")
        .font(.caption2)
    }
    .padding()
    .previewDisplayName("toSpeech")

    // MARK: Speech Locale & Style
    VStack(alignment: .leading, spacing: 8) {
      LaTeX("$x^2 + y^2 = z^2$")
        .speechLocale(.english)
        .speechStyle(.default)

      LaTeX("$x^2 + y^2 = z^2$")
        .speechLocale(.german)
        .speechStyle(.brief)
    }
    .padding()
    .previewDisplayName("Speech Locale & Style")

    // MARK: Display Alignment
    VStack(alignment: .leading, spacing: 12) {
      LaTeX("$$x^2 + y^2 = z^2$$")
        .displayAlignment(.left)

      LaTeX("$$x^2 + y^2 = z^2$$")
        .displayAlignment(.center)

      LaTeX("$$x^2 + y^2 = z^2$$")
        .displayAlignment(.right)
    }
    .padding()
    .previewDisplayName("Display Alignment")

    // MARK: TeX Packages
    VStack(alignment: .leading, spacing: 12) {
      Text("Chemistry")
        .font(.caption)
      LaTeX("$\\ce{2H2 + O2 -> 2H2O}$")
        .texPackages(LaTeX.chemistryPackages)

      Text("Physics")
        .font(.caption)
      LaTeX("$\\bra{\\psi}\\ket{\\phi}$")
        .texPackages(LaTeX.physicsPackages)

      Text("Math (cancel)")
        .font(.caption)
      LaTeX("$\\cancel{x} + \\bcancel{y} = z$")
        .texPackages(LaTeX.mathPackages)

      Text("Logic")
        .font(.caption)
      LaTeX("$A \\implies B$")
        .texPackages(LaTeX.logicPackages)
    }
    .padding()
    .previewDisplayName("TeX Packages")

    // MARK: Autoload
    VStack(alignment: .leading, spacing: 12) {
      Text("Autoload enabled (default)")
        .font(.caption)
      LaTeX("$\\ce{H2O + CO2 -> H2CO3}$")

      Text("Autoload disabled + explicit packages")
        .font(.caption)
      LaTeX("$\\ce{H2O}$")
        .texPackages([.base, .ams, .mhchem])
        .texAutoload(false)
    }
    .padding()
    .previewDisplayName("Autoload")
  }

}

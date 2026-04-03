//
//  LineSpacingNormalizer.swift
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

/// A text renderer that normalizes line spacing when some lines contain
/// inline equation images with baseline offsets that inflate line height.
///
/// Works by computing baseline-to-baseline distances between adjacent lines,
/// finding the minimum (the natural text-only spacing), and shifting inflated
/// lines closer while clamping to prevent overlap.
@available(iOS 18.0, macOS 15.0, *)
internal struct LineSpacingNormalizer: TextRenderer {

  func draw(layout: Text.Layout, in context: inout GraphicsContext) {
    let corrections = computeCorrections(layout)

    for (index, line) in layout.enumerated() {
      var lineContext = context
      lineContext.translateBy(x: 0, y: -corrections[index])
      lineContext.draw(line)
    }
  }

  func sizeThatFits(proposal: ProposedViewSize, text: Text.Layout) -> CGSize {
    let corrections = computeCorrections(text)

    var size = CGSize.zero
    for line in text {
      let bounds = line.typographicBounds
      size.width = max(size.width, bounds.width)
      size.height = bounds.rect.maxY
    }

    if let lastCorrection = corrections.last {
      size.height -= lastCorrection
    }

    return size
  }

  private func computeCorrections(_ layout: Text.Layout) -> [CGFloat] {
    let lines = Array(layout)
    guard lines.count > 1 else {
      return Array(repeating: 0, count: lines.count)
    }

    // Get baseline Y positions for each line.
    let baselines = lines.map { $0.typographicBounds.origin.y }

    // Compute baseline-to-baseline gaps between adjacent lines.
    var gaps = [CGFloat]()
    for i in 1..<lines.count {
      gaps.append(baselines[i] - baselines[i - 1])
    }

    // The minimum gap is the natural text-only baseline-to-baseline distance.
    guard let normalGap = gaps.min(), normalGap > 0 else {
      return Array(repeating: 0, count: lines.count)
    }

    // For each line after the first, accumulate the excess gap and clamp
    // to prevent the current line from overlapping the previous line's
    // descent region.
    var corrections = [CGFloat](repeating: 0, count: lines.count)
    var cumulativeCorrection: CGFloat = 0

    for i in 1..<lines.count {
      let excess = gaps[i - 1] - normalGap
      cumulativeCorrection += max(0, excess)

      // Clamp: ensure the current line's top doesn't go above the
      // previous line's bottom after correction.
      let prevBottom = baselines[i - 1] + lines[i - 1].typographicBounds.descent - corrections[i - 1]
      let currTop = baselines[i] - lines[i].typographicBounds.ascent - cumulativeCorrection
      if currTop < prevBottom {
        cumulativeCorrection -= (prevBottom - currTop)
      }

      corrections[i] = cumulativeCorrection
    }

    return corrections
  }
}

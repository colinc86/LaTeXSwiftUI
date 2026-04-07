//
//  FontTests.swift
//  LaTeXSwiftUI
//
//  Created by Colin Campbell on 4/6/26.
//

import SwiftUI
import XCTest
@testable import LaTeXSwiftUI

final class FontTests: XCTestCase {

  // MARK: - textStyle() returns the correct text style for each font

  func testTextStyleForPlainFonts() {
    XCTAssertEqual(Font.largeTitle.textStyle(), .largeTitle)
    XCTAssertEqual(Font.title.textStyle(), .title1)
    XCTAssertEqual(Font.title2.textStyle(), .title2)
    XCTAssertEqual(Font.title3.textStyle(), .title3)
    XCTAssertEqual(Font.headline.textStyle(), .headline)
    XCTAssertEqual(Font.subheadline.textStyle(), .subheadline)
    XCTAssertEqual(Font.callout.textStyle(), .callout)
    XCTAssertEqual(Font.caption.textStyle(), .caption1)
    XCTAssertEqual(Font.caption2.textStyle(), .caption2)
    XCTAssertEqual(Font.footnote.textStyle(), .footnote)
    XCTAssertEqual(Font.body.textStyle(), .body)
  }

  func testTextStyleForBoldFonts() {
    XCTAssertEqual(Font.title.bold().textStyle(), .title1)
    XCTAssertEqual(Font.title2.bold().textStyle(), .title2)
    XCTAssertEqual(Font.title3.bold().textStyle(), .title3)
    XCTAssertEqual(Font.body.bold().textStyle(), .body)
  }

  func testTextStyleForItalicFonts() {
    XCTAssertEqual(Font.title.italic().textStyle(), .title1)
    XCTAssertEqual(Font.title2.italic().textStyle(), .title2)
    XCTAssertEqual(Font.title3.italic().textStyle(), .title3)
    XCTAssertEqual(Font.body.italic().textStyle(), .body)
  }

  /// Regression test: title2.monospaced() and title3.monospaced() must
  /// return the correct text style, not fall through to nil.
  func testTextStyleForMonospacedFonts() {
    XCTAssertEqual(Font.title.monospaced().textStyle(), .title1)
    XCTAssertEqual(Font.title2.monospaced().textStyle(), .title2)
    XCTAssertEqual(Font.title3.monospaced().textStyle(), .title3)
    XCTAssertEqual(Font.body.monospaced().textStyle(), .body)
    XCTAssertEqual(Font.caption.monospaced().textStyle(), .caption1)
  }

  // MARK: - effectiveXHeight returns different values per script

  func testEffectiveXHeightLatin() {
    let font = _Font.preferredFont(forTextStyle: .body)
    let xh = font.effectiveXHeight(for: .latin)
    XCTAssertEqual(xh, font.xHeight)
  }

  func testEffectiveXHeightCJK() {
    let font = _Font.preferredFont(forTextStyle: .body)
    let xh = font.effectiveXHeight(for: .cjk)
    XCTAssertEqual(xh, font.capHeight)
    XCTAssertGreaterThan(xh, font.xHeight, "capHeight should be larger than xHeight")
  }

  func testEffectiveXHeightCustom() {
    let font = _Font.preferredFont(forTextStyle: .body)
    let factor: CGFloat = 1.5
    let xh = font.effectiveXHeight(for: .custom(factor))
    XCTAssertEqual(xh, font.xHeight * factor, accuracy: 0.001)
  }

  // MARK: - Different font sizes produce different x-heights

  func testXHeightVariesWithFontSize() {
    let bodyXH = Font.body.xHeight
    let titleXH = Font.title.xHeight
    XCTAssertNotEqual(bodyXH, titleXH, "Body and title should have different x-heights")
    XCTAssertGreaterThan(titleXH, bodyXH, "Title x-height should be larger than body")
  }

}

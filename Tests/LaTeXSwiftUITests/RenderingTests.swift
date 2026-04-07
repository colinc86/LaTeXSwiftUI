//
//  RenderingTests.swift
//  LaTeXSwiftUI
//
//  Created by Colin Campbell on 4/6/26.
//

import MathJaxSwift
import XCTest
@testable import LaTeXSwiftUI

final class RenderingTests: XCTestCase {

  // MARK: - SVG data attribute escaping

  func testSVGEscapesAngleBracketsInDataAttributes() throws {
    let mathjax = try MathJax(preferredOutputFormat: .svg)
    let texOptions = TeXInputProcessorOptions(processEscapes: false, errorMode: .original)

    // This produces data-latex attributes containing < and >
    let input = "x < 0"
    var error: Error?
    let svgString = mathjax.tex2svg(
      input, styles: false,
      conversionOptions: ConversionOptions(display: false),
      inputOptions: texOptions, error: &error)
    XCTAssertNil(error)

    // SVG init should not throw — the escaping handles the < in data-latex
    let svg = try SVG(svgString: svgString)
    let output = String(data: svg.data, encoding: .utf8)!
    XCTAssertFalse(output.contains("data-latex=\"x < 0\""), "Raw < should be escaped in attributes")
  }

  // MARK: - Validation

  func testValidateValidEquation() {
    XCTAssertNoThrow(try LaTeX.validate("x^2 + y^2 = z^2"))
  }

  func testValidateInvalidEquation() {
    XCTAssertThrowsError(try LaTeX.validate("\\frac{}")) { error in
      XCTAssertTrue(error is LaTeX.ValidationError)
    }
  }

  func testIsValidReturnsTrueForValid() {
    XCTAssertTrue(LaTeX.isValid("x^2"))
  }

  func testIsValidReturnsFalseForInvalid() {
    XCTAssertFalse(LaTeX.isValid("\\frac{}"))
  }

  // MARK: - MathML conversion

  func testToMathMLProducesOutput() throws {
    let result = try LaTeX.toMathML("x^2")
    XCTAssertTrue(result.contains("<math"), "Should produce MathML output")
    XCTAssertTrue(result.contains("</math>"), "Should have closing math tag")
  }

  // MARK: - Speech conversion

  func testToSpeechProducesOutput() throws {
    let result = try LaTeX.toSpeech("x^2")
    XCTAssertFalse(result.isEmpty, "Speech output should not be empty")
  }

  func testToSpeechBriefStyle() throws {
    let defaultResult = try LaTeX.toSpeech("\\frac{a}{b}")
    let briefResult = try LaTeX.toSpeech("\\frac{a}{b}", style: .brief)
    // Brief style should generally produce shorter or equal output
    XCTAssertFalse(briefResult.isEmpty)
    XCTAssertFalse(defaultResult.isEmpty)
  }

  // MARK: - renderToImages

  func testRenderToImagesProducesImages() {
    let images = LaTeX.renderToImages("Hello $x^2$ world $y$")
    XCTAssertEqual(images.count, 2, "Should render 2 equation images")
  }

  func testRenderToImagesAllMode() {
    // With onlyEquations mode, text without delimiters has no equations
    let images = LaTeX.renderToImages("x^2 + y^2")
    XCTAssertEqual(images.count, 0, "No delimiters means no equations in onlyEquations mode")
  }

  func testRenderToImagesWithBlockEquation() {
    let images = LaTeX.renderToImages("$$\\int_0^1 x dx$$")
    XCTAssertEqual(images.count, 1)
  }

  // MARK: - CSSLength

  func testCSSLengthDescription() {
    XCTAssertEqual(LaTeX.CSSLength.em(1.5).description, "1.5em")
    XCTAssertEqual(LaTeX.CSSLength.px(100).description, "100.0px")
    XCTAssertEqual(LaTeX.CSSLength.percent(50).description, "50.0%")
  }

  // MARK: - Notation sniffing edge cases

  func testAutoNotationWithMathML() throws {
    // MathML input should be detected and converted correctly
    let mml = "<math><mi>x</mi><mo>+</mo><mn>1</mn></math>"
    XCTAssertNoThrow(try LaTeX.validate(mml, notation: .auto))
  }

  func testAutoNotationWithLaTeX() throws {
    XCTAssertNoThrow(try LaTeX.validate("\\frac{a}{b}", notation: .auto))
  }

  // MARK: - Cache operations

  func testCacheKeyDeterminism() throws {
    // Verify that the same SVGCacheKey produces the same hash on repeated calls
    let texOptions = TeXInputProcessorOptions(processEscapes: false, errorMode: .rendered)
    let convOpts = ConversionOptions(display: false)
    let cacheKey = Cache.SVGCacheKey(
      componentText: "test_determinism",
      conversionOptions: convOpts,
      inputOptions: .tex(texOptions))

    // Store something
    let data = "test".data(using: .utf8)!
    Cache.shared.setDataCacheValue(data, for: cacheKey)

    // Retrieve with the SAME key object
    let retrieved = Cache.shared.dataCacheValue(for: cacheKey)
    XCTAssertNotNil(retrieved, "Cache lookup with the same key object should succeed")

    // Clean up
    if retrieved != nil {
      Cache.shared.removeDataCacheValue(for: cacheKey)
    }
  }

  /// Verifies that different inputs don't collide in the cache.
  func testCacheDoesNotCollide() throws {
    let mathjax = try MathJax(preferredOutputFormat: .svg)
    let texOptions = TeXInputProcessorOptions(processEscapes: false, errorMode: .rendered)
    let convOpts = ConversionOptions(display: false)

    // Render two different equations
    var error: Error?
    let svg1String = mathjax.tex2svg("x^2", styles: false, conversionOptions: convOpts, inputOptions: texOptions, error: &error)
    XCTAssertNil(error)
    let svg2String = mathjax.tex2svg("y^3", styles: false, conversionOptions: convOpts, inputOptions: texOptions, error: &error)
    XCTAssertNil(error)

    let svg1 = try SVG(svgString: svg1String)
    let svg2 = try SVG(svgString: svg2String)

    // Use the same ConversionOptions instance for both store and retrieve
    let key1 = Cache.SVGCacheKey(componentText: "x^2", conversionOptions: convOpts, inputOptions: .tex(texOptions))
    let key2 = Cache.SVGCacheKey(componentText: "y^3", conversionOptions: convOpts, inputOptions: .tex(texOptions))

    Cache.shared.setDataCacheValue(try svg1.encoded(), for: key1)
    Cache.shared.setDataCacheValue(try svg2.encoded(), for: key2)

    // Retrieve each and verify they're different
    guard let retrieved1 = Cache.shared.dataCacheValue(for: key1),
          let retrieved2 = Cache.shared.dataCacheValue(for: key2) else {
      // If the cache doesn't round-trip, that itself is a finding
      // but not a crash — skip the rest of the test
      XCTFail("Cache should store and retrieve data for different keys")
      return
    }

    let decoded1 = try SVG(data: retrieved1)
    let decoded2 = try SVG(data: retrieved2)

    XCTAssertNotEqual(decoded1.geometry.width, decoded2.geometry.width, "Different equations should have different widths")

    // Clean up
    Cache.shared.removeDataCacheValue(for: key1)
    Cache.shared.removeDataCacheValue(for: key2)
  }

  // MARK: - SVG geometry edge cases

  func testSVGGeometryNegativeAlignment() throws {
    // Equations with subscripts have negative vertical alignment
    let mathjax = try MathJax(preferredOutputFormat: .svg)
    let texOptions = TeXInputProcessorOptions(processEscapes: false, errorMode: .rendered)
    var error: Error?
    let svgString = mathjax.tex2svg(
      "x_i", styles: false,
      conversionOptions: ConversionOptions(display: false),
      inputOptions: texOptions, error: &error)
    XCTAssertNil(error)

    let svg = try SVG(svgString: svgString)
    XCTAssertLessThan(svg.geometry.verticalAlignment, 0, "Subscript equations should have negative vertical alignment")
    XCTAssertGreaterThan(svg.geometry.width, 0)
    XCTAssertGreaterThan(svg.geometry.height, 0)
  }

  func testSVGGeometrySimpleVariable() throws {
    let mathjax = try MathJax(preferredOutputFormat: .svg)
    let texOptions = TeXInputProcessorOptions(processEscapes: false, errorMode: .rendered)
    var error: Error?
    let svgString = mathjax.tex2svg(
      "x", styles: false,
      conversionOptions: ConversionOptions(display: false),
      inputOptions: texOptions, error: &error)
    XCTAssertNil(error)

    let svg = try SVG(svgString: svgString)
    // A simple "x" should have near-zero vertical alignment
    XCTAssertEqual(svg.geometry.verticalAlignment, 0, accuracy: 0.05)
    XCTAssertGreaterThan(svg.geometry.width, 0)
    XCTAssertGreaterThan(svg.geometry.height, 0)
  }

  func testSVGSizeScalesWithXHeight() throws {
    let mathjax = try MathJax(preferredOutputFormat: .svg)
    let texOptions = TeXInputProcessorOptions(processEscapes: false, errorMode: .rendered)
    var error: Error?
    let svgString = mathjax.tex2svg(
      "x^2", styles: false,
      conversionOptions: ConversionOptions(display: false),
      inputOptions: texOptions, error: &error)
    XCTAssertNil(error)

    let svg = try SVG(svgString: svgString)
    let size1 = svg.size(for: 5.0)
    let size2 = svg.size(for: 10.0)

    XCTAssertEqual(size2.width, size1.width * 2, accuracy: 0.001, "Width should scale linearly with x-height")
    XCTAssertEqual(size2.height, size1.height * 2, accuracy: 0.001, "Height should scale linearly with x-height")
  }

  // MARK: - TeX packages

  func testAutoloadOptionAffectsPackages() {
    let withAutoload = TeXInputProcessorOptions(processEscapes: false, errorMode: .rendered, packages: [.base, .ams], autoload: true)
    let withoutAutoload = TeXInputProcessorOptions(processEscapes: false, errorMode: .rendered, packages: [.base, .ams], autoload: false)

    XCTAssertTrue(withAutoload.loadPackages.contains("autoload"))
    XCTAssertFalse(withoutAutoload.loadPackages.contains("autoload"))
  }

  // MARK: - Validation edge cases

  func testValidateEmptyString() {
    // Empty string should be valid (no error from MathJax)
    XCTAssertNoThrow(try LaTeX.validate(""))
  }

  func testValidateWithProcessEscapes() {
    XCTAssertNoThrow(try LaTeX.validate("x^2", processEscapes: true))
  }

  func testValidateMathML() {
    let mml = "<math><mi>x</mi></math>"
    XCTAssertNoThrow(try LaTeX.validate(mml, notation: .mml))
  }

  func testIsValidConvenience() {
    XCTAssertTrue(LaTeX.isValid("x^2 + y^2"))
    XCTAssertFalse(LaTeX.isValid("\\frac{}"))
  }

  // MARK: - Display vs inline rendering

  func testDisplayAndInlineBothRender() throws {
    let mathjax = try MathJax(preferredOutputFormat: .svg)
    let texOptions = TeXInputProcessorOptions(processEscapes: false, errorMode: .rendered)
    var error: Error?

    let inlineSVGString = mathjax.tex2svg(
      "x^2", styles: false,
      conversionOptions: ConversionOptions(display: false),
      inputOptions: texOptions, error: &error)
    XCTAssertNil(error)

    let displaySVGString = mathjax.tex2svg(
      "x^2", styles: false,
      conversionOptions: ConversionOptions(display: true),
      inputOptions: texOptions, error: &error)
    XCTAssertNil(error)

    let inline = try SVG(svgString: inlineSVGString)
    let display = try SVG(svgString: displaySVGString)

    XCTAssertGreaterThan(inline.geometry.width, 0)
    XCTAssertGreaterThan(display.geometry.width, 0)
  }

  // MARK: - Error handling

  func testSVGWithConversionError() throws {
    let mathjax = try MathJax(preferredOutputFormat: .svg)
    // Use options that surface errors (no noerrors/noundefined)
    let texOptions = TeXInputProcessorOptions(processEscapes: false, errorMode: .error)
    var error: Error?

    let svgString = mathjax.tex2svg(
      "\\invalidcommand", styles: false,
      conversionOptions: ConversionOptions(display: false),
      inputOptions: texOptions, error: &error)

    // MathJax should produce an error
    XCTAssertNotNil(error)

    // But the SVG string should still be parseable (MathJax embeds error in SVG)
    let svg = try SVG(svgString: svgString, errorText: "test error")
    XCTAssertEqual(svg.errorText, "test error")
    XCTAssertGreaterThan(svg.geometry.width, 0)
  }

  // MARK: - renderToImages edge cases

  func testRenderToImagesEmptyInput() {
    let images = LaTeX.renderToImages("")
    XCTAssertEqual(images.count, 0)
  }

  func testRenderToImagesTextOnly() {
    let images = LaTeX.renderToImages("Just plain text, no equations")
    XCTAssertEqual(images.count, 0)
  }

  func testRenderToImagesMultipleEquations() {
    let images = LaTeX.renderToImages("$x$ and $y$ and $z$")
    XCTAssertEqual(images.count, 3)
    for image in images {
      XCTAssertGreaterThan(image.size.width, 0)
      XCTAssertGreaterThan(image.size.height, 0)
    }
  }

  func testRenderToImagesWithCustomXHeight() {
    let images1 = LaTeX.renderToImages("$x^2$", xHeight: 5.0)
    let images2 = LaTeX.renderToImages("$x^2$", xHeight: 10.0)
    XCTAssertEqual(images1.count, 1)
    XCTAssertEqual(images2.count, 1)
    XCTAssertGreaterThan(images2[0].size.width, images1[0].size.width)
  }

  func testRenderToImagesWithHTMLEntities() {
    let images = LaTeX.renderToImages("$x &lt; 0$", unencodeHTML: true)
    XCTAssertEqual(images.count, 1)
  }

  // MARK: - toMathML edge cases

  func testToMathMLFraction() throws {
    let result = try LaTeX.toMathML("\\frac{a}{b}")
    XCTAssertTrue(result.contains("<mfrac>"), "Fraction should produce mfrac element")
  }

  func testToMathMLPassthroughForMML() throws {
    let mml = "<math><mi>x</mi></math>"
    let result = try LaTeX.toMathML(mml, notation: .mml)
    XCTAssertEqual(result, mml)
  }

  // MARK: - Component type properties

  func testComponentTypeInlineProperty() {
    XCTAssertTrue(Component.ComponentType.text.inline)
    XCTAssertTrue(Component.ComponentType.inlineEquation.inline)
    XCTAssertTrue(Component.ComponentType.inlineParenthesesEquation.inline)
    XCTAssertFalse(Component.ComponentType.texEquation.inline)
    XCTAssertFalse(Component.ComponentType.blockEquation.inline)
    XCTAssertFalse(Component.ComponentType.namedEquation.inline)
    XCTAssertFalse(Component.ComponentType.namedNoNumberEquation.inline)
    XCTAssertFalse(Component.ComponentType.namedEnvironment("align").inline)
  }

  func testComponentTypeIsEquation() {
    XCTAssertFalse(Component.ComponentType.text.isEquation)
    XCTAssertTrue(Component.ComponentType.inlineEquation.isEquation)
    XCTAssertTrue(Component.ComponentType.texEquation.isEquation)
    XCTAssertTrue(Component.ComponentType.blockEquation.isEquation)
    XCTAssertTrue(Component.ComponentType.namedEquation.isEquation)
    XCTAssertTrue(Component.ComponentType.namedEnvironment("cases").isEquation)
  }

  func testComponentTypeTerminators() {
    XCTAssertNil(Component.ComponentType.text.leftTerminator)
    XCTAssertEqual(Component.ComponentType.inlineEquation.leftTerminator, "$")
    XCTAssertEqual(Component.ComponentType.inlineEquation.rightTerminator, "$")
    XCTAssertEqual(Component.ComponentType.texEquation.leftTerminator, "$$")
    XCTAssertEqual(Component.ComponentType.texEquation.rightTerminator, "$$")
    XCTAssertEqual(Component.ComponentType.blockEquation.leftTerminator, "\\[")
    XCTAssertEqual(Component.ComponentType.blockEquation.rightTerminator, "\\]")
    XCTAssertEqual(Component.ComponentType.namedEnvironment("align").leftTerminator, "\\begin{align}")
    XCTAssertEqual(Component.ComponentType.namedEnvironment("align").rightTerminator, "\\end{align}")
  }

  // MARK: - SVG encoding roundtrip

  func testSVGEncodingRoundtrip() throws {
    let mathjax = try MathJax(preferredOutputFormat: .svg)
    let texOptions = TeXInputProcessorOptions(processEscapes: false, errorMode: .rendered)
    var error: Error?
    let svgString = mathjax.tex2svg(
      "\\sqrt{x}", styles: false,
      conversionOptions: ConversionOptions(display: false),
      inputOptions: texOptions, error: &error)
    XCTAssertNil(error)

    let svg = try SVG(svgString: svgString)
    let encoded = try svg.encoded()
    let decoded = try SVG(data: encoded)

    XCTAssertEqual(svg.geometry.width, decoded.geometry.width)
    XCTAssertEqual(svg.geometry.height, decoded.geometry.height)
    XCTAssertEqual(svg.geometry.verticalAlignment, decoded.geometry.verticalAlignment)
    XCTAssertEqual(svg.data, decoded.data)
    XCTAssertEqual(svg.errorText, decoded.errorText)
  }

  // MARK: - Image cache key includes displayScale

  func testImageCacheKeyDiffersForDisplayScale() throws {
    let mathjax = try MathJax(preferredOutputFormat: .svg)
    let texOptions = TeXInputProcessorOptions(processEscapes: false, errorMode: .rendered)
    var error: Error?
    let svgString = mathjax.tex2svg(
      "x", styles: false,
      conversionOptions: ConversionOptions(display: false),
      inputOptions: texOptions, error: &error)
    XCTAssertNil(error)

    let svg = try SVG(svgString: svgString)
    let key1x = Cache.ImageCacheKey(svg: svg, xHeight: 6.0, displayScale: 1.0)
    let key2x = Cache.ImageCacheKey(svg: svg, xHeight: 6.0, displayScale: 2.0)

    #if os(iOS) || os(visionOS)
    let dummyImage = UIImage()
    #else
    let dummyImage = NSImage()
    #endif
    Cache.shared.setImageCacheValue(dummyImage, for: key1x)

    XCTAssertNotNil(Cache.shared.imageCacheValue(for: key1x), "1x key should find cached image")
    XCTAssertNil(Cache.shared.imageCacheValue(for: key2x), "2x key should NOT find 1x cached image")

    Cache.shared.removeImageCacheValue(for: key1x)
  }

}

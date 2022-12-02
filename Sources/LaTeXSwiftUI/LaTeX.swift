//
//  LaTeX.swift
//  LaTeXSwiftUI
//
//  Created by Colin Campbell on 11/29/22.
//

import MathJaxSwift
import SwiftDraw
import SwiftUI
import SVGView

@available(iOS 16.1, *)
struct LaTeX: View {
  
  enum RenderingStyle {
    
    /// Render the entire text as the equation.
    case all
    
    /// Find equations in the text and only render the equations.
    case equations
  }
  
  /// The display scale.
  @Environment(\.displayScale) private var displayScale
  
  /// The view's color scheme.
  @Environment(\.colorScheme) private var colorScheme
  
  /// The components to display in the view.
  @State private var components: [LaTeXEquationParser.LaTeXComponent]
  
  /// The view's MathJax instance.
  private let mathjax: MathJax?
  
  /// The view's font size.
  private let fontSize: CGFloat
  
  // MARK: Initializers
  
  /// Creates a LaTeX text view.
  ///
  /// - Parameters:
  ///   - text: The text input.
  ///   - style: Whether or not the entire input, or only equations, should be
  ///     parsed.
  ///   - fontSize: The size of the view's font.
  init(_ text: String, style: RenderingStyle = .equations, fontSize: CGFloat = UIFont.systemFontSize) {
    self.fontSize = fontSize
    self.mathjax = try? MathJax(preferredOutputFormat: .svg)
    _components = State(wrappedValue: style == .all ? [LaTeXEquationParser.LaTeXComponent(text: text, type: .inlineEquation)] : LaTeXEquationParser.parse(text))
  }
  
  // MARK: View body
  
  var body: some View {
    text
      .font(.system(size: fontSize))
      .fontDesign(.serif)
      .onAppear(perform: appeared)
      .onChange(of: colorScheme, perform: changedColorScheme)
  }
  
  // MARK: Private views
  
  /// The text to draw in the view.
  private var text: some View {
    var text = Text("")
    for component in components {
      if let image = component.svg {
        text = text + Text(Image(uiImage: image)).baselineOffset(-(fontSize / 3.6))
      }
      else {
        text = text + Text(component.text)
      }
    }
    return text
  }
  
}

@available(iOS 16.1, *)
extension LaTeX {
  
  /// Called when the view appears.
  private func appeared() {
    Task {
      do {
        try await render()
      }
      catch {
        
      }
    }
  }
  
  /// Called when the color scheme changes.
  ///
  /// - Parameter newValue: The new color scheme.
  private func changedColorScheme(to newValue: ColorScheme) {
    appeared()
  }
  
  /// Called when the math components should be (re)rendered.
  @MainActor private func render() async throws {
    var newComponents = [LaTeXEquationParser.LaTeXComponent]()
    for component in components {
      guard component.type.isEquation else {
        newComponents.append(component)
        continue
      }
      
      guard let svgString = try await mathjax?.tex2svg(component.text, inline: component.type.inline) else {
        continue
      }
      
      let svgData = svgString.data(using: .utf8)!
      
      let svg = SVG(data: svgData)

      let size = svg?.size ?? .zero
      let newSize = CGSize(width: size.width * (fontSize / 1.8), height: size.height * (fontSize / 1.8))
      
      let view = SVGView(data: svgData)
      
      var uiImage: UIImage?
      if colorScheme == .dark {
        let renderer = ImageRenderer(content: view.colorInvert().frame(width: newSize.width, height: newSize.height))
        renderer.scale = displayScale
        uiImage = renderer.uiImage
      }
      else {
        let renderer = ImageRenderer(content: view.frame(width: newSize.width, height: newSize.height))
        renderer.scale = displayScale
        uiImage = renderer.uiImage
      }
      
      newComponents.append(LaTeXEquationParser.LaTeXComponent(text: component.text, type: component.type, svg: uiImage))
    }
    
    withAnimation {
      self.components = newComponents
    }
  }
  
}

@available(iOS 16.1, *)
struct LaTeX_Previews: PreviewProvider {
  static var previews: some View {
    VStack {
      HStack {
        Text("Input Text:")
        Spacer()
      }
      .font(.subheadline)
      
      Text("It's working! $\\frac{-b\\pm\\sqrt{b^2-4ac}}{2a}$")
        .font(.system(size: 14))
        .padding([.bottom], 8)
      
      HStack {
        Text("LaTeX Image:")
        Spacer()
      }
      .font(.subheadline)
      
      LaTeX("\\text{It's working! }\\frac{-b\\pm\\sqrt{b^2-4ac}}{2a}", style: .all, fontSize: 24.0)
      
      HStack {
        Text("SwiftUI View:")
        Spacer()
      }
      .font(.subheadline)
      
      LaTeX("It's working! $\\frac{-b\\pm\\sqrt{b^2-4ac}}{2a}$", fontSize: 24.0)
    }
    
    VStack {
      HStack {
        Text("Input Text:")
        Spacer()
      }
      .font(.subheadline)
      
      Text("This is a cool title that talks about $\\zeta(3)$ and how hard it is.")
        .font(.system(size: 14))
        .padding([.bottom], 8)
      
      HStack {
        Text("LaTeX Image:")
        Spacer()
      }
      .font(.subheadline)
      
      LaTeX("\\text{This is a cool title that talks about }\\zeta(3)\\text{ and how hard it is to solve.}", style: .all, fontSize: 24.0)
      
      HStack {
        Text("SwiftUI View:")
        Spacer()
      }
      .font(.subheadline)
      
      LaTeX("This is a cool title that talks about $\\zeta(3)$ and how hard it is to solve.", fontSize: 24.0)
    }
    .preferredColorScheme(.dark)
  }
}

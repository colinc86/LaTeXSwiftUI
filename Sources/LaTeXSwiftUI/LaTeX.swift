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
    case all
    case equations
  }
  
  @Environment(\.displayScale) var displayScale
  @Environment(\.colorScheme) var colorScheme
  
  @State private var components: [LaTeXEquationParser.LaTeXComponent]
  private let mathjax: MathJax?
  private let fontSize: CGFloat
  
  init(_ text: String, style: RenderingStyle = .equations, fontSize: CGFloat = UIFont.systemFontSize) {
    self.fontSize = fontSize
    self.mathjax = try? MathJax(preferredOutputFormat: .svg)
    _components = State(wrappedValue: style == .all ? [LaTeXEquationParser.LaTeXComponent(text: text, type: .inlineEquation)] : LaTeXEquationParser.parse(text))
  }
  
  // MARK: View body
  
  var text: some View {
    var text = Text("")
    for component in components {
      if let image = component.svg {
        text = text + Text(Image(uiImage: image)).baselineOffset(-(fontSize / 4.0))
      }
      else {
        text = text + Text(component.text)
      }
    }
    return text
  }
  
  var body: some View {
    text
      .font(.system(size: fontSize))
      .fontDesign(.serif)
      .onAppear(perform: appeared)
      .onChange(of: colorScheme, perform: changedColorScheme)
  }
  
}

@available(iOS 16.1, *)
extension LaTeX {
  
  private func appeared() {
    Task {
      do {
        try await render()
      }
      catch {
        
      }
    }
  }
  
  private func changedColorScheme(to newValue: ColorScheme) {
    appeared()
  }
  
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
      let newSize = CGSize(width: size.width * (fontSize / 2.0), height: size.height * (fontSize / 2.0))
      
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
      LaTeX("It's working! $\\frac{-b\\pm\\sqrt{b^2-4ac}}{2a}$", fontSize: 24.0)
      LaTeX("\\text{It's working! }\\frac{-b\\pm\\sqrt{b^2-4ac}}{2a}", style: .all, fontSize: 24.0)
    }
    
    VStack {
      LaTeX("It's working! $\\frac{-b\\pm\\sqrt{b^2-4ac}}{2a}$", fontSize: 24.0)
      LaTeX("\\text{It's working! }\\frac{-b\\pm\\sqrt{b^2-4ac}}{2a}", style: .all, fontSize: 24.0)
    }
    .preferredColorScheme(.dark)
  }
}

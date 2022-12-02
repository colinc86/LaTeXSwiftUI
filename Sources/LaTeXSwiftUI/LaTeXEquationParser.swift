//
//  LaTeXEquationParser.swift
//  LaTeXSwiftUI
//
//  Created by Colin Campbell on 11/30/22.
//

import Foundation
import UIKit

internal class LaTeXEquationParser {
  
  /// A LaTeX component.
  struct LaTeXComponent: CustomStringConvertible, Equatable, Hashable {
    
    /// A LaTeX component type.
    enum ComponentType: String, Equatable, CustomStringConvertible {
      
      /// A text component.
      case text
      
      /// An inline equation component.
      ///
      /// - Example: `$x^2$`
      case inlineEquation
      
      /// A multiline equation component.
      ///
      /// - Example: `\[x^2\]`
      case multilineEquation
      
      /// A named equation component.
      ///
      /// - Example: `\begin{equation}x^2\end{equation}`
      case namedEquation
      
      /// The component's description.
      var description: String {
        rawValue
      }
      
      /// The component's left terminator.
      var leftTerminator: String {
        switch self {
        case .text: return ""
        case .inlineEquation: return "$"
        case .multilineEquation: return "\\["
        case .namedEquation: return "\\begin{equation}"
        }
      }
      
      /// The component's right terminator.
      var rightTerminator: String {
        switch self {
        case .text: return ""
        case .inlineEquation: return "$"
        case .multilineEquation: return "\\]"
        case .namedEquation: return "\\end{equation}"
        }
      }
      
      /// Whether or not this component is inline.
      var inline: Bool {
        switch self {
        case .text, .inlineEquation: return true
        default: return false
        }
      }
      
      /// True iff the component is not `text`.
      var isEquation: Bool {
        return self != .text
      }
    }
    
    /// The component's inner text.
    let text: String
    
    /// The component's type.
    let type: ComponentType
    
    /// The component's SVG image.
    let svg: UIImage?
    
    // MARK: Initializers
    
    /// Initializes a component.
    ///
    /// The text passed to the component is stripped of the left and right
    /// terminators defined in the component's type.
    ///
    /// - Parameters:
    ///   - text: The component's text.
    ///   - type: The component's type.
    init(text: String, type: ComponentType, svg: UIImage? = nil) {
      if type.isEquation {
        var text = text
        if text.hasPrefix(type.leftTerminator) {
          text = String(text[text.index(text.startIndex, offsetBy: type.leftTerminator.count)...])
        }
        if text.hasSuffix(type.rightTerminator) {
          text = String(text[..<text.index(text.startIndex, offsetBy: text.count - type.rightTerminator.count)])
        }
        self.text = text
      }
      else {
        self.text = text
      }
      
      self.type = type
      self.svg = svg
    }
    
    /// The component's description.
    var description: String {
      return "(\(type), \"\(text)\")"
    }
    
  }
  
  /// An equation component.
  struct EquationComponent<T, U> {
    let regex: Regex<T>
    let terminatingRegex: Regex<U>
    let equation: LaTeXComponent.ComponentType
    let supportsRecursion: Bool
  }
  
  /// An inline equation component.
  static let inline = EquationComponent(
    regex: #/\$(.|\s)*\$/#,
    terminatingRegex: #/\$/#,
    equation: .inlineEquation,
    supportsRecursion: false)
  
  /// A multiline equation component.
  static let multiline = EquationComponent(
    regex: #/\\\[(.|\s)*\\\]/#,
    terminatingRegex: #/\\\]/#,
    equation: .multilineEquation,
    supportsRecursion: true)
  
  /// A named equation component.
  static let named = EquationComponent(
    regex: #/\\begin{equation}(.|\s)*\\end{equation}/#,
    terminatingRegex: #/\\end{equation}/#,
    equation: .namedEquation,
    supportsRecursion: true)
  
  // Order matters
  static let allEquations = [inline, multiline, named]
  
}

extension LaTeXEquationParser {
  
  /// Parses an input string for LaTeX components.
  ///
  /// - Parameter input: The input string.
  /// - Returns: An array of LaTeX components.
  static func parse(_ input: String) -> [LaTeXComponent] {
    let matches = allEquations.map({ ($0, input.firstMatch(of: $0.regex)) }).filter { match in
      guard let firstIndex = match.1?.range.lowerBound,
            let lastIndex = match.1?.range.upperBound else { return false }
      
      let previousIndexLast = input.index(lastIndex, offsetBy: -1 - match.0.equation.rightTerminator.count)
      
      if firstIndex == input.startIndex {
        return input[previousIndexLast] != "\\"
      }
      
      let previousIndexFirst = input.index(before: firstIndex)
      return input[previousIndexFirst] != "\\" && input[previousIndexLast] != "\\"
    }
    
    let allStart = matches.map({ $0.1?.range.lowerBound })
    var equationRange: Range<String.Index>?
    var equation: LaTeXComponent.ComponentType = .text
    
    for match in matches {
      guard isSmallest(match.1?.range.lowerBound, outOf: allStart) else {
        continue
      }
      guard let matchRange = match.1?.range else {
        continue
      }
      
      if match.0.supportsRecursion {
        let terminatingMatches = input.matches(of: match.0.terminatingRegex).filter { match in
          let index = match.range.lowerBound
          if index == input.startIndex { return true }
          let previousIndex = input.index(before: index)
          return input[previousIndex] != "\\"
        }
        if let lastMatch = terminatingMatches.last {
          equationRange = matchRange.lowerBound ..< lastMatch.range.upperBound
        }
      }
      else {
        equationRange = match.1?.range
      }
      
      if equationRange != nil {
        equation = match.0.equation
        break
      }
    }
    
    if let equationRange = equationRange {
      let stringBeforeEquation = String(input[..<equationRange.lowerBound])
      let equationString = String(input[equationRange])
      let remainingString = String(input[equationRange.upperBound...])
      var components = [LaTeXComponent]()
      if !stringBeforeEquation.isEmpty {
        components.append(LaTeXComponent(text: stringBeforeEquation, type: .text))
      }
      components.append(LaTeXComponent(text: equationString, type: equation))
      if remainingString.isEmpty {
        return components
      }
      else {
        return components + parse(remainingString)
      }
    }
    
    return input.isEmpty ? [] : [LaTeXComponent(text: input, type: .text)]
  }
  
  /// Determines if an index is smaller than all of the indexes in another
  /// array.
  ///
  /// - Parameters:
  ///   - index: The index to compare.
  ///   - indexes: The indexes. The value `index` should not be present in this.
  /// - Returns: A boolean.
  static func isSmallest(_ index: String.Index?, outOf indexes: [String.Index?]) -> Bool {
    guard let index = index else { return false }
    let indexes = indexes.filter({ $0 != nil }).map({ $0! }) as! [String.Index]
    return indexes.first(where: { $0 < index }) == nil
  }
  
}

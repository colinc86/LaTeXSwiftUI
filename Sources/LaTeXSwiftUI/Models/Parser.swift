//
//  Parser.swift
//  LaTeXSwiftUI
//
//  Created by Colin Campbell on 11/30/22.
//

import Foundation

/// Parses LaTeX equations.
internal struct Parser {
  
  // MARK: Types
  
  /// An equation component.
  private struct EquationComponent<T, U> {
    let regex: Regex<T>
    let terminatingRegex: Regex<U>
    let equation: Component.ComponentType
    let supportsRecursion: Bool
  }
  
  // MARK: Private properties
  
  /// An inline equation component.
  private static let inline = EquationComponent(
    regex: #/\$(.|\s)*?\$/#,
    terminatingRegex: #/\$/#,
    equation: .inlineEquation,
    supportsRecursion: false)
  
  /// An TeX-style block equation component.
  private static let tex = EquationComponent(
    regex: #/\$\$(.|\s)*?\$\$/#,
    terminatingRegex: #/\$\$/#,
    equation: .texEquation,
    supportsRecursion: false)
  
  /// A block equation.
  private static let block = EquationComponent(
    regex: #/\\\[(.|\s)*?\\\]/#,
    terminatingRegex: #/\\\]/#,
    equation: .blockEquation,
    supportsRecursion: false)
  
  /// A named equation component.
  private static let named = EquationComponent(
    regex: #/\\begin{equation}(.|\s)*\\end{equation}/#,
    terminatingRegex: #/\\end{equation}/#,
    equation: .namedEquation,
    supportsRecursion: true)
  
  /// A named no number equation component.
  private static let namedNoNumber = EquationComponent(
    regex: #/\\begin{equation\*}(.|\s)*\\end{equation\*}/#,
    terminatingRegex: #/\\end{equation\*}/#,
    equation: .namedNoNumberEquation,
    supportsRecursion: true)
  
  // Order matters
  private static let allEquations: [EquationComponent] = [
    inline,
    tex,
    block,
    named,
    namedNoNumber
  ]
  
}

// MARK: Static methods

extension Parser {
  
  /// Parses the input text for component blocks.
  ///
  /// - Parameters:
  ///   - text: The input text.
  ///   - mode: The rendering mode.
  /// - Returns: An array of component blocks.
  static func parse(_ text: String, mode: LaTeX.ParsingMode) -> [ComponentBlock] {
    let components = mode == .all ? [Component(text: text, type: .inlineEquation)] : parse(text)
    var blocks = [ComponentBlock]()
    var blockComponents = [Component]()
    for component in components {
      if component.type.inline {
        blockComponents.append(component)
      }
      else {
        blocks.append(ComponentBlock(components: blockComponents))
        blocks.append(ComponentBlock(components: [component]))
        blockComponents.removeAll()
      }
    }
    if !blockComponents.isEmpty {
      blocks.append(ComponentBlock(components: blockComponents))
    }
    return blocks
  }
  
  /// Parses an input string for LaTeX components.
  ///
  /// - Parameter input: The input string.
  /// - Returns: An array of LaTeX components.
  static func parse(_ input: String) -> [Component] {
    // Get the first match of each each equation type
    let matches = allEquations.map({ ($0, input.firstMatch(of: $0.regex)) })
    
    // Filter the matches
    let filteredMatches = matches.filter { match in
      // We only want matches with ranges
      guard let range = match.1?.range else {
        return false
      }
      
      // Make sure the inner component is non-empty
      let text = Component(text: String(input[range]), type: match.0.equation).text
      guard !text.isEmpty else {
        return false
      }
      
      // Make sure the starting terminator isn't escaped
      guard range.lowerBound >= input.startIndex else {
        return false
      }
      if range.lowerBound > input.startIndex, input[input.index(before: range.lowerBound)] == "\\" {
        return false
      }
      
      // Make sure the ending terminator isn't escaped
      let endingTerminatorStartIndex = input.index(range.upperBound, offsetBy: -match.0.equation.rightTerminator.count)
      guard endingTerminatorStartIndex >= input.startIndex else {
        return false
      }
      if endingTerminatorStartIndex > input.startIndex, input[input.index(before: endingTerminatorStartIndex)] == "\\" {
        return false
      }
      
      // The component has content and isn't escaped
      return true
    }
    
    // Get the first matched equation
    guard let smallestMatch = filteredMatches.min(by: { $0.1!.range.lowerBound < $1.1!.range.lowerBound }) else {
      return input.isEmpty ? [] : [Component(text: input, type: .text)]
    }

    // If the equation supports recursion, then we'll need to find the last
    // match of its terminating regex component.
    let equationRange: Range<String.Index>
    if smallestMatch.0.supportsRecursion {
      var terminatingMatches = input.matches(of: smallestMatch.0.terminatingRegex).filter { match in
        // Make sure the terminator isn't escaped
        if match.range.lowerBound == input.startIndex { return true }
        let previousIndex = input.index(before: match.range.lowerBound)
        return input[previousIndex] != "\\"
      }
      terminatingMatches.sort(by: { $0.range.lowerBound < $1.range.lowerBound })
      if let lastMatch = terminatingMatches.last {
        equationRange = smallestMatch.1!.range.lowerBound ..< lastMatch.range.upperBound
      }
      else {
        equationRange = smallestMatch.1!.range
      }
    }
    else {
      equationRange = smallestMatch.1!.range
    }

    // We got our equation range, so lets return the components.
    let stringBeforeEquation = String(input[..<equationRange.lowerBound])
    let equationString = String(input[equationRange])
    let remainingString = String(input[equationRange.upperBound...])
    var components = [Component]()
    if !stringBeforeEquation.isEmpty {
      components.append(Component(text: stringBeforeEquation, type: .text))
    }
    components.append(Component(text: equationString, type: smallestMatch.0.equation))
    if remainingString.isEmpty {
      return components
    }
    else {
      return components + parse(remainingString)
    }
  }
  
}

// MARK: Private static methods

extension Parser {
  
  /// Determines if an index is smaller than all of the indexes in another
  /// array.
  ///
  /// - Parameters:
  ///   - index: The index to compare.
  ///   - indexes: The indexes. The value `index` should not be present in this.
  /// - Returns: A boolean.
  private static func isSmallest(_ index: String.Index?, outOf indexes: [String.Index?]) -> Bool {
    guard let index = index else { return false }
    let indexes = indexes.filter({ $0 != nil }).map({ $0! }) as! [String.Index]
    return indexes.first(where: { $0 < index }) == nil
  }
  
}

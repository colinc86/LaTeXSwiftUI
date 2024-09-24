//
//  Parser.swift
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

import Foundation

/// Parses LaTeX equations.
internal struct Parser {
  
  // MARK: Types
  
  /// An equation component.
  struct EquationComponent<T, U> {
    let regex: Regex<T>
    let terminatingRegex: Regex<U>
    let equation: Component.ComponentType
  }
  
  // MARK: Private properties
  
  /// An inline equation component.
  static let inline = EquationComponent(
    regex: #/\$(.*?)\$/#,
    terminatingRegex: #/\$/#,
    equation: .inlineEquation)

  static let inlineParen = EquationComponent(
    regex: #/\\\(\s*(.*?)\s*\\\)/#,
    terminatingRegex: #/\\\)/#,
    equation: .inlineParenEquation)

  /// An TeX-style block equation component.
  static let tex = EquationComponent(
    regex: #/\$\$\s*(.*?)\s*\$\$/#,
    terminatingRegex: #/\$\$/#,
    equation: .texEquation)
  
  /// A block equation.
  static let block = EquationComponent(
    regex: #/\\\[\s*(.*?)\s*\\\]/#,
    terminatingRegex: #/\\\]/#,
    equation: .blockEquation)
  
  /// A named equation component.
  static let named = EquationComponent(
    regex: #/\\begin{equation}\s*(.*?)\s*\\end{equation}/#,
    terminatingRegex: #/\\end{equation}/#,
    equation: .namedEquation)
  
  /// A named no number equation component.
  static let namedNoNumber = EquationComponent(
    regex: #/\\begin{equation\*}\s*(.*?)\s*\\end{equation\*}/#,
    terminatingRegex: #/\\end{equation\*}/#,
    equation: .namedNoNumberEquation)
  
  // Order matters
  static let allEquations: [EquationComponent] = [
    inline,
    inlineParen,
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
    let matchArrays = allEquations.map { equationComponent in
      let regexMatches = input.matches(of: equationComponent.regex)
      return regexMatches.map({ (equationComponent, $0) })
    }
    
    let matches = matchArrays.reduce([], +)
    
    // Filter the matches
    let filteredMatches = matches.filter { match in
      // We only want matches with ranges
      let range = match.1.range
      
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
      
      // Make sure the range isn't in any other range.
      // I.e. we only use top-level matches.
      for subMatch in matches {
        let subRange = subMatch.1.range
        
        if range.isSubrange(of: subRange) {
          return false
        }
      }
      
      // The component has content and isn't escaped
      return true
    }
    
    // Get the first matched equation
    guard let smallestMatch = filteredMatches.min(by: { $0.1.range.lowerBound < $1.1.range.lowerBound }) else {
      return input.isEmpty ? [] : [Component(text: input, type: .text)]
    }

    // If the equation supports recursion, then we'll need to find the last
    // match of its terminating regex component.
    let equationRange: Range<String.Index> = smallestMatch.1.range

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

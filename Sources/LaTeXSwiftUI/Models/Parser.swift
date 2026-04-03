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

/// Parses text for LaTeX equations.
internal enum Parser {

  /// Notation hint tags recognized before opening delimiters.
  private static let notationHints: [(tag: String, notation: LaTeX.Notation)] = [
    ("[latex]", .latex),
    ("[mml]", .mml),
    ("[am]", .am),
    ("[auto]", .auto),
  ]

  /// Parses the input text for component blocks.
  ///
  /// - Parameters:
  ///   - text: The input text.
  ///   - mode: The rendering mode.
  /// - Returns: An array of component blocks.
  static func parse(_ text: String, mode: LaTeX.ParsingMode) -> [ComponentBlock] {
    let components: [Component]
    if mode == .all {
      // Check for a leading notation hint when the entire input is one equation
      let hint = notationHints.first { text.hasPrefix($0.tag) }
      if let hint {
        let stripped = String(text[text.index(text.startIndex, offsetBy: hint.tag.count)...])
        components = [Component(text: stripped, type: .inlineEquation, notationHint: hint.notation)]
      } else {
        components = [Component(text: text, type: .inlineEquation)]
      }
    } else {
      components = parse(text)
    }
    var blocks = [ComponentBlock]()
    var blockComponents = [Component]()
    for component in components {
      if component.type.inline {
        blockComponents.append(component)
      } else {
        if !blockComponents.isEmpty {
          blocks.append(ComponentBlock(components: blockComponents))
          blockComponents.removeAll()
        }
        blocks.append(ComponentBlock(components: [component]))
      }
    }
    if !blockComponents.isEmpty {
      blocks.append(ComponentBlock(components: blockComponents))
    }
    return blocks
  }
  
  /// Parses the input text in to components.
  ///
  /// - Parameter input: The input text.
  /// - Returns: An array of components.
  static func parse(_ input: String) -> [Component] {
    var components: [Component] = []
    var stack = [Component.ComponentType]()
    var index = input.startIndex
    // `textGapStart` marks where the preceding text gap begins (at the hint
    // tag if present, otherwise at the opening delimiter).
    // `delimStart` marks the opening delimiter itself (equation text).
    var textGapStart = index
    var delimStart = index
    var endIndex = index
    var currentHint: LaTeX.Notation? = nil

    inputLoop: while index < input.endIndex {
      var remaining = input[index...]

      if !stack.isEmpty {
        for type in Component.ComponentType.order {
          guard let end = type.rightTerminator else { continue }
          if remaining.hasPrefix(end) {
            if index > input.startIndex && input[input.index(before: index)] == "\\" {
              index = input.index(index, offsetBy: end.count)
              continue inputLoop
            }

            if stack.last == type {
              let newEndIndex = input.index(index, offsetBy: end.count)
              let lastType = stack.removeLast()
              if stack.isEmpty {
                if endIndex < textGapStart {
                  components.append(Component(text: String(input[endIndex..<textGapStart]), type: .text))
                }
                components.append(Component(text: String(input[delimStart..<newEndIndex]), type: lastType, notationHint: currentHint))
                currentHint = nil
              }
              endIndex = newEndIndex
              index = newEndIndex
              continue inputLoop
            }
          }
        }

        // Check for generic \end{...} closing a named environment
        if remaining.hasPrefix("\\end{") {
          let searchStart = remaining.index(remaining.startIndex, offsetBy: 5)
          if let closeBrace = remaining[searchStart...].firstIndex(of: "}") {
            let name = String(remaining[searchStart..<closeBrace])
            if case .namedEnvironment(let stackName) = stack.last, stackName == name {
              let terminator = "\\end{\(name)}"
              let newEndIndex = input.index(index, offsetBy: terminator.count)
              let lastType = stack.removeLast()
              if stack.isEmpty {
                if endIndex < textGapStart {
                  components.append(Component(text: String(input[endIndex..<textGapStart]), type: .text))
                }
                components.append(Component(text: String(input[delimStart..<newEndIndex]), type: lastType, notationHint: currentHint))
                currentHint = nil
              }
              endIndex = newEndIndex
              index = newEndIndex
              continue inputLoop
            }
          }
        }
      }

      // Check for a notation hint before an opening delimiter
      if stack.isEmpty {
        for (tag, notation) in notationHints {
          if remaining.hasPrefix(tag) {
            let afterTag = input.index(index, offsetBy: tag.count)
            let rest = input[afterTag...]
            let hasDelimiter = Component.ComponentType.order.contains {
              $0.leftTerminator.map { rest.hasPrefix($0) } ?? false
            } || rest.hasPrefix("\\begin{")
            if hasDelimiter {
              currentHint = notation
              textGapStart = index
              index = afterTag
              remaining = input[index...]
              break
            }
          }
        }
      }

      for type in Component.ComponentType.order {
        guard let start = type.leftTerminator else { continue }
        if remaining.hasPrefix(start) {
          if index > input.startIndex && input[input.index(before: index)] == "\\" {
            index = input.index(index, offsetBy: start.count)
            continue inputLoop
          }

          if stack.isEmpty {
            if currentHint == nil {
              textGapStart = index
            }
            delimStart = index
          }

          stack.append(type)
          index = input.index(index, offsetBy: start.count)
          continue inputLoop
        }
      }

      // Check for generic \begin{...} opening a named environment
      if remaining.hasPrefix("\\begin{") {
        let searchStart = remaining.index(remaining.startIndex, offsetBy: 7)
        if let closeBrace = remaining[searchStart...].firstIndex(of: "}") {
          let name = String(remaining[searchStart..<closeBrace])
          // equation and equation* are handled by the static types above
          if name != "equation" && name != "equation*" {
            if stack.isEmpty {
              if currentHint == nil {
                textGapStart = index
              }
              delimStart = index
            }
            let type = Component.ComponentType.namedEnvironment(name)
            stack.append(type)
            let terminator = "\\begin{\(name)}"
            index = input.index(index, offsetBy: terminator.count)
            continue inputLoop
          }
        }
      }

      index = input.index(after: index)
    }

    // If the stack is non-empty, the opening delimiter was unmatched.
    // Treat the text from the previous endIndex through end-of-input
    // as plain text (the unmatched delimiter is not a real equation).
    if !stack.isEmpty {
      stack.removeAll()
      currentHint = nil
      if endIndex < index {
        components.append(Component(text: String(input[endIndex..<index]), type: .text))
      }
      return components
    }

    if endIndex < index {
      components.append(Component(text: String(input[endIndex..<index]), type: .text))
    }

    return components
  }
}

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

class Parser {
  
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
      } else {
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
  
  static func parse(_ input: String) -> [Component] {
    var components: [Component] = []
    var stack = [Component.ComponentType]()
    var index = input.startIndex
    var startIndex = index
    var endIndex = index
    
    inputLoop: while index < input.endIndex {
      let remaining = input[index...]
      
      if !stack.isEmpty {
        for type in Component.ComponentType.order {
          guard let end = type.rightTerminator else { continue }
          if remaining.hasPrefix(end) {
            if index > input.startIndex && input[input.index(before: index)] == "\\" {
              index = input.index(index, offsetBy: end.count)
              continue inputLoop
            }
            
            let previousEndIndex = endIndex
            endIndex = input.index(index, offsetBy: end.count)

            if stack.last == type {
              let lastType = stack.removeLast()
              if stack.isEmpty {
                if previousEndIndex < startIndex {
                  components.append(Component(text: String(input[previousEndIndex..<startIndex]), type: .text))
                }
                
                components.append(Component(text: String(input[startIndex..<endIndex]), type: lastType))
              }
            }
            index = endIndex
            continue inputLoop
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
            startIndex = index
          }
          
          stack.append(type)
          index = input.index(index, offsetBy: start.count)
          continue inputLoop
        }
      }
      
      index = input.index(after: index)
    }
    
    if endIndex < index {
      components.append(Component(text: String(input[endIndex..<index]), type: .text))
    }
    
    return components
  }
}

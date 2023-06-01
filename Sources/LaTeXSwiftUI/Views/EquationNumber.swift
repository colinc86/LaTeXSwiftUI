//
//  EquationNumber.swift
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

struct EquationNumber: View {
  
  enum EquationSide {
    case left
    case right
  }
  
  let blockIndex: Int
  let side: EquationSide
  
  @Environment(\.equationNumberMode) private var equationNumberMode
  @Environment(\.equationNumberStart) private var equationNumberStart
  @Environment(\.equationNumberOffset) private var equationNumberOffset
  
    var body: some View {
      switch equationNumberMode {
      case .left:
        if side == .left {
          Text("(\(equationNumberStart + blockIndex))")
            .padding([.leading], equationNumberOffset)
        }
        else {
          Text("(\(equationNumberStart + blockIndex))")
            .padding([.leading], equationNumberOffset)
            .foregroundColor(.clear)
        }
        Spacer(minLength: 0)
      case .right:
        Spacer(minLength: 0)
        if side == .right {
          Text("(\(equationNumberStart + blockIndex))")
            .padding([.trailing], equationNumberOffset)
        }
        else {
          Text("(\(equationNumberStart + blockIndex))")
            .padding([.trailing], equationNumberOffset)
            .foregroundColor(.clear)
        }
      default:
        EmptyView()
      }
    }
}

struct EquationNumber_Previews: PreviewProvider {
    static var previews: some View {
      EquationNumber(blockIndex: 0, side: .left)
        .environment(\.equationNumberMode, .left)
    }
}

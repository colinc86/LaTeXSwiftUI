//
//  CGRect+Extensions.swift
//  LaTeXSwiftUI
//
//  Created by Colin Campbell on 12/8/22.
//

import Foundation

extension CGRect: Hashable {
  
  public func hash(into hasher: inout Hasher) {
    hasher.combine("x\(origin.x)")
    hasher.combine("y\(origin.y)")
    hasher.combine("w\(size.width)")
    hasher.combine("h\(size.height)")
  }
  
}

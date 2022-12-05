//
//  EnvironmentValues+Extensions.swift
//  LaTeXSwiftUI
//
//  Created by Colin Campbell on 12/4/22.
//

import Foundation
import SwiftUI

private struct TextColorKey: EnvironmentKey {
  static let defaultValue: Color? = nil
}

extension EnvironmentValues {
  public var textColor: Color? {
    get { self[TextColorKey.self] }
    set { self[TextColorKey.self] = newValue }
  }
}

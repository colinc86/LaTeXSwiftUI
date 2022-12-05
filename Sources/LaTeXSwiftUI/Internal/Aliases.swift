//
//  Aliases.swift
//  LaTeXSwiftUI
//
//  Created by Colin Campbell on 12/4/22.
//

import Foundation

#if os(iOS)
import UIKit
internal typealias _Image = UIImage
internal typealias _Font = UIFont
internal typealias _Color = UIColor
#else
import Cocoa
internal typealias _Image = NSImage
internal typealias _Font = NSFont
internal typealias _Color = NSColor
#endif

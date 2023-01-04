//
//  Logger.swift
//  LaTeXSwiftUI
//
//  Created by Colin Campbell on 12/8/22.
//

import Foundation
import Logging

/// The applications main logger.
fileprivate var logger: Logger = {
  var log = Logger(label: "latexswiftui")
  
#if DEBUG
  log.logLevel = .trace
#else
  log.logLevel = .info
#endif
  
  return log
}()

@inlinable
internal func logError(_ message: String, _ file: StaticString = #file, _ function: StaticString = #function, _ line: UInt = #line) {
  logger.error(createMessage(from: message, file: file, function: function, line: line))
}

// MARK: Private methods
/// Creates a log message.
/// - Parameters:
///   - message: The message's value.
///   - file: The file string.
///   - line: The line number.
/// - Returns: A formatted logger message.
internal func createMessage(from message: String, file: StaticString, function: StaticString, line: UInt) -> Logger.Message {
  let filename = ("\(file)".components(separatedBy: "/").last ?? "").components(separatedBy: ".").first ?? ""
  let function = "\(function)".components(separatedBy: "(").first ?? ""
  return Logger.Message("[\(filename).\(function):\(line)] \(message)")
}

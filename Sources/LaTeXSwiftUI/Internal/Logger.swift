//
//  Logger.swift
//  LaTeXSwiftUI
//
//  Created by Colin Campbell on 12/8/22.
//

import Foundation
import Logging

/// The applications main logger.
public var logger: Logger = {
  var log = Logger(label: "latexswiftui")
  
#if DEBUG
  log.logLevel = .trace
#else
  log.logLevel = .info
#endif
  
  return log
}()

@inlinable
public func logTrace(_ message: @autoclosure () -> String, _ file: StaticString = #file, _ function: StaticString = #function, _ line: UInt = #line) {
  logger.trace(createMessage(from: message(), file: file, function: function, line: line))
}

@inlinable
public func logDebug(_ message: String, _ file: StaticString = #file, _ function: StaticString = #function, _ line: UInt = #line) {
  logger.debug(createMessage(from: message, file: file, function: function, line: line))
}

@inlinable
public func logInfo(_ message: String, _ file: StaticString = #file, _ function: StaticString = #function, _ line: UInt = #line) {
  logger.info(createMessage(from: message, file: file, function: function, line: line))
}

@inlinable
public func logNotice(_ message: String, _ file: StaticString = #file, _ function: StaticString = #function, _ line: UInt = #line) {
  logger.info(createMessage(from: message, file: file, function: function, line: line))
}

@inlinable
public func logWarning(_ message: String, _ file: StaticString = #file, _ function: StaticString = #function, _ line: UInt = #line) {
  logger.warning(createMessage(from: message, file: file, function: function, line: line))
}

@inlinable
public func logError(_ message: String, _ file: StaticString = #file, _ function: StaticString = #function, _ line: UInt = #line) {
  logger.error(createMessage(from: message, file: file, function: function, line: line))
}

@inlinable
public func logCritical(_ message: String, _ file: StaticString = #file, _ function: StaticString = #function, _ line: UInt = #line) {
  logger.critical(createMessage(from: message, file: file, function: function, line: line))
}

// MARK: Private methods
/// Creates a log message.
/// - Parameters:
///   - message: The message's value.
///   - file: The file string.
///   - line: The line number.
/// - Returns: A formatted logger message.
public func createMessage(from message: String, file: StaticString, function: StaticString, line: UInt) -> Logger.Message {
  let filename = ("\(file)".components(separatedBy: "/").last ?? "").components(separatedBy: ".").first ?? ""
  let function = "\(function)".components(separatedBy: "(").first ?? ""
  return Logger.Message("[\(filename).\(function):\(line)] \(message)")
}

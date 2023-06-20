//
//  Cache.swift
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

import CryptoKit
import Foundation
import MathJaxSwift

fileprivate protocol CacheKey: Codable {
  
  /// The key type used to identify the cache key in storage.
  static var keyType: String { get }
  
  /// A key to use if encoding fails.
  var fallbackKey: String { get }
  
}

extension CacheKey {
  
  /// The key to use in the cache.
  func key() -> String {
    do {
      let data = try JSONEncoder().encode(self)
      let hashedData = SHA256.hash(data: data)
      return hashedData.compactMap { String(format: "%02x", $0) }.joined() + "-" + Self.keyType
    }
    catch {
      return fallbackKey + "-" + Self.keyType
    }
  }
  
}

internal class Cache {
  
  // MARK: Types
  
  /// An SVG cache key.
  struct SVGCacheKey: CacheKey {
    static let keyType: String = "svg"
    let componentText: String
    let conversionOptions: ConversionOptions
    let texOptions: TeXInputProcessorOptions
    internal var fallbackKey: String { componentText }
  }
  
  /// An image cache key.
  struct ImageCacheKey: CacheKey {
    static let keyType: String = "image"
    let svg: SVG
    let xHeight: CGFloat
    internal var fallbackKey: String { String(data: svg.data, encoding: .utf8) ?? "" }
  }
  
  // MARK: Static properties
  
  /// The renderer's data cache.
  internal let dataCache: NSCache<NSString, NSData> = NSCache()
  
  /// Semaphore for thread-safe access to `dataCache`.
  internal let dataCacheSemaphore = DispatchSemaphore(value: 1)
  
  /// The renderer's image cache.
  internal let imageCache: NSCache<NSString, _Image> = NSCache()
  
  /// Semaphore for thread-safe access to `imageCache`.
  internal let imageCacheSemaphore = DispatchSemaphore(value: 1)
  
}

// MARK: Public methods

extension Cache {
  
  /// Safely access the cache value for the given key.
  ///
  /// - Parameter key: The key of the value to get.
  /// - Returns: A value.
  func dataCacheValue(for key: SVGCacheKey) -> Data? {
    dataCacheSemaphore.wait()
    defer { dataCacheSemaphore.signal() }
    return dataCache.object(forKey: key.key() as NSString) as Data?
  }
  
  /// Safely sets the cache value.
  ///
  /// - Parameters:
  ///   - value: The value to set.
  ///   - key: The value's key.
  func setDataCacheValue(_ value: Data, for key: SVGCacheKey) {
    dataCacheSemaphore.wait()
    dataCache.setObject(value as NSData, forKey: key.key() as NSString)
    dataCacheSemaphore.signal()
  }
  
  /// Safely access the cache value for the given key.
  ///
  /// - Parameter key: The key of the value to get.
  /// - Returns: A value.
  func imageCacheValue(for key: ImageCacheKey) -> _Image? {
    imageCacheSemaphore.wait()
    defer { imageCacheSemaphore.signal() }
    return imageCache.object(forKey: key.key() as NSString)
  }
  
  /// Safely sets the cache value.
  ///
  /// - Parameters:
  ///   - value: The value to set.
  ///   - key: The value's key.
  func setImageCacheValue(_ value: _Image, for key: ImageCacheKey) {
    imageCacheSemaphore.wait()
    imageCache.setObject(value, forKey: key.key() as NSString)
    imageCacheSemaphore.signal()
  }
  
}

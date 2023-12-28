//
//  File.swift
//  
//
//  Created by gebiwanger on 2023/12/21.
//

import Foundation

extension String {
  public func components(_ separator: String, autoSuffix: Bool = true) -> [String] {
    let hasSuffixSymbol = self.hasSuffix(separator)
    
    var r = self.components(separatedBy: separator).compactMap { v -> [String]? in
      guard !v.isEmpty else {
        return nil
      }
      return [v]
    }.flatMap { $0 }
    
    if autoSuffix {
      r = r.map { "\($0)\(separator)" }
    }
    
    if autoSuffix, !hasSuffixSymbol, let last = r.last {
      r.removeLast()
      r.append(String(last.dropLast(separator.count)))
    }

    return r
  }
}

extension Array where Element == String {
  func components(_ separator: [(String,Bool)]) -> [String] {
    var r: [String] = self
    for (k,v) in separator {
      r = r.flatMap { m in
        m.components(k, autoSuffix: v)
      }
    }
    return r
  }
  
  func checkMin(_ min: UInt8) -> [String] {
    self
      .compactMap { v -> [String]? in
        guard v.count >= min else {
          return nil
        }
        return [v]
      }
      .flatMap { $0 }
  }
}

public struct HLVParse {
  
  static var linesSymbol: [String] = ["\u{2028}", "\u{2029}", "\u{0009}", "\u{000A}", "\u{000B}", "\u{000C}", "\u{000D}", "\n", "\\n"]
  public static func appendLinesSymbol(_ symbols: [String]) {
    linesSymbol.append(contentsOf: symbols)
  }
  
  static var zhSymbol: [(String,Bool)] = [("。",true), ("！",true), ("；",true), ("？",true)]
  public static func appendZhSymbol(_ symbol: String) {
    zhSymbol.append((symbol, false))
  }
  
  public static func parseLines(_ text: String) -> [String] {
    [text]
      .components(linesSymbol.map({ ($0, false) }))
      .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
  }
  
  public static func parseZh(_ text: String, minZhNum: UInt8 = 1) -> [String] {
    parseLines(text)
      .components(zhSymbol)
      .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
      .compactMap { v -> [String]? in
        var num = minZhNum
        for scalar in v.unicodeScalars {
          guard num > 0 else {
            break
          }
          if 0x4E00...0x9FFF ~= scalar.value {
            num -= 1
          }
        }
        return num == 0 ? [v] : nil
      }
      .flatMap { $0 }
  }
}

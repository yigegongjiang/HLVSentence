//
//  File.swift
//  
//
//  Created by gebiwanger on 2023/12/21.
//

import Foundation
import NaturalLanguage

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
  
  public func checkSpace() -> [String] {
    self.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
  }
  
  func components(_ separators: [(String,Bool)]) -> [String] {
    var r: [String] = self
    for (k,v) in separators {
      r = r.flatMap { m in
        m.components(k, autoSuffix: v)
      }
    }
    r = r.checkSpace()
    return r
  }
  
  func nlp() -> [String] {
    self.flatMap { v in
      var sentence: [String] = []
      let tokenizer = NLTokenizer(unit: .sentence)
      tokenizer.string = v
      tokenizer.enumerateTokens(in: v.startIndex..<v.endIndex) { range, _ in
        let t = String(v[range])
        if !t.isEmpty, t.count > 0 {
          sentence.append(t)
        }
        return true
      }
      return sentence
    }
  }
  
  public func checkZhMin(minWords: UInt8 = 1) -> [String] {
    self.flatMap { v -> [String] in
      var num = minWords > 1 ? minWords : 1
      for scalar in v.unicodeScalars {
        guard num > 0 else {
          break
        }
        if 0x4E00...0x9FFF ~= scalar.value {
          num -= 1
        }
      }
      return num == 0 ? [v] : []
    }
  }
  
  public func checkMin(minWords: UInt8 = 1) -> [String] {
    self.flatMap { v -> [String] in
      v.count >= (minWords > 1 ? minWords : 1) ? [v] : []
    }
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
  
  public static func parseZh(_ text: String, minWords: UInt8 = 1) -> [String] {
    [text]
      .components(linesSymbol.map({ ($0, false) }))
      .components(zhSymbol)
      .nlp()
      .checkZhMin(minWords: minWords)
  }
  
  public static func parse(_ text: String, minWords: UInt8 = 1) -> [String] {
    [text]
      .components(linesSymbol.map({ ($0, false) }))
      .nlp()
      .checkMin(minWords: minWords)
  }
}

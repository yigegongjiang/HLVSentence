//
//  File.swift
//  
//
//  Created by gebiwanger on 2023/12/29.
//

import Foundation
import SwiftShell
#if canImport(Combine)
import Combine
#endif

public enum HLVTextCorrectError: Error {
  case python3EnvInstall
}

public typealias HLVTextCorrectResult = [(first: String, last: String, errors:[Any])]

public protocol HLVTextCorrectProtocol {
  static func correct(_ texts: [String], _ completion: @escaping (Result<HLVTextCorrectResult, HLVTextCorrectError>) -> Void)
}

public struct HLVTextCorrect: HLVTextCorrectProtocol {
  
  public static var envPath: String?
  static let pytext = """

  from pycorrector import MacBertCorrector

  m = MacBertCorrector("shibing624/macbert4csc-base-chinese")

  print(m.correct_batch(<replace>, max_length=500, batch_size=32, threshold=0.7, silent=True))

  """
  
  // 解析汉字及常用中文符号
  static func extract(_ text: String) -> String {
      do {
          let regex = try NSRegularExpression(pattern: "[\\p{Han}。，；！：？]+", options: .caseInsensitive)
          let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))

          let result = matches.map {
              String(text[Range($0.range, in: text)!])
          }.joined()

          return result
      } catch {
          return text
      }
  }
  
  public static func correct(_ texts: [String], _ completion: @escaping (Result<HLVTextCorrectResult, HLVTextCorrectError>) -> Void) {
    
    let raw = texts.map { extract($0) }
    let input = "['\(raw.joined(separator: "','"))']"
    let _pytext = pytext.replacingOccurrences(of: "<replace>", with: input)
    
    var context: CustomContext = SwiftShell.CustomContext(SwiftShell.main)
    if let path = HLVTextCorrect.envPath, !path.isEmpty {
      context.env["PATH"] = path
    }
    context.runAsync("python3", "-c", _pytext).onCompletion { (out: AsyncCommand) in
      var r = out.stdout.read()
      r = r.replacingOccurrences(of: "'", with: "\"")
      r = r.replacingOccurrences(of: "(", with: "[")
      r = r.replacingOccurrences(of: ")", with: "]")
      /* r value like:
      [{
        "source": "虽然可以通过快捷键来新建tab，但是手势滚动一下，还是要比按下键盘舒服的多。",
        "target": "虽然可以通过快捷键来新建tab，但是手势滚动一下，还是要比按下键盘舒服舒多。多。",
        "errors": [["的", "舒", 35]]
      }]
       */
      
      guard let jsonData = r.data(using: .utf8) else {
        completion(.failure(.python3EnvInstall))
        return
      }
      
      guard let raw_correct = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [[String: Any]] else {
        completion(.failure(.python3EnvInstall))
        return
      }
      
      var correct: [(String,String,[Any])] = []
      for item in raw_correct {
        if let source = item["source"] as? String, let target = item["target"] as? String, let errors = item["errors"] as? [[Any]] {
          if !errors.isEmpty && source.count == target.count {
            correct.append((source, target, errors))
          }
        }
      }
      
      completion(.success(correct))
    }
  }
}

public extension HLVTextCorrectProtocol {
  static func correct(_ texts: [String]) async throws -> HLVTextCorrectResult {
    try await withCheckedThrowingContinuation { continuation in
      correct(texts) { result in
        switch result {
        case let .success(success):
            return continuation.resume(returning: success)
        case let .failure(failure):
            return continuation.resume(throwing: failure)
        }
      }
    }
  }
  
#if canImport(Combine)
  static func correct(_ texts: [String]) -> AnyPublisher<HLVTextCorrectResult, HLVTextCorrectError> {
    Future<HLVTextCorrectResult, HLVTextCorrectError> {
      correct(texts, $0)
    }
    .eraseToAnyPublisher()
  }
#endif
}

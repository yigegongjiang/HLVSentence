// The Swift Programming Language
// https://docs.swift.org/swift-book
// 
// Swift Argument Parser
// https://swiftpackageindex.com/apple/swift-argument-parser/documentation

import ArgumentParser
import Foundation
import HLVSentence
import HLVFileDump
import Down
import Dispatch

@main
struct Command: ParsableCommand {
  static var configuration = CommandConfiguration(
    abstract: "Parse Signal Sentence From Files/Folder/Text.",
    version: "1.0.2",
    subcommands: [Files.self, Folder.self, Text.self],
    defaultSubcommand: Files.self
  )
  
  mutating func run() throws {
    print("Hello, world!")
  }
}  
  
class HLVParseInit {
  private init() {
    HLVParse.appendZhSymbol("///")
    HLVParse.appendZhSymbol("//")
    HLVParse.appendZhSymbol("/*")
    HLVParse.appendZhSymbol("*/")
  }
  static var `default`: HLVParseInit { HLVParseInit() }
}

struct Options: ParsableArguments {
  @Flag(name: .short, help: "need parse markdown.")
  var markdown = false
  
  @Flag(name: .short, help: "need text correct.")
  var correct = false

  @Flag(name: .short, help: "open zh-cn sentence.")
  var zh = false

  @Option(name: .customShort("n"), help: "min sentence words.")
  var minWords: UInt8 = 2
}

extension Command {
  
  static func parseText(_ text: String, correct: Bool, zh: Bool, path: String?, minWords: UInt8) {
    _ = HLVParseInit.default
    
    var r: [String]
    if zh {
      r = HLVParse.parseZh(text, minWords: minWords)
    } else {
      r = HLVParse.parse(text, minWords: minWords)
    }
    
    if let path  {
      print("\(path):")
    }
    for i in 0..<r.count {
      print("\(i): \(r[i])")
    }    
    print("\(r.isEmpty ? "Cannot find effective sentence.\n" : "")")
    
    if !r.isEmpty, correct {
      let semaphore = DispatchSemaphore(value: 0)

      actor _Data {
        var result: [(first: String, last: String, errors:[Any])] = []
        
        func modifyResult(newValue: [(first: String, last: String, errors:[Any])]) {
          result = newValue
        }
        
        func readResult() -> [(first: String, last: String, errors:[Any])] {
          return result
        }
      }
      
      let _data = _Data()
      let _r = r
      
      Task {
        do {
          let result = try await HLVTextCorrect.correct(_r)
          await _data.modifyResult(newValue: result)
          semaphore.signal()
        } catch {
          hlvexit(HLVError.custom("Text Correct Field. May need to install python3 and pycorrector. see: https://github.com/shibing624/pycorrector"))
        }
      }
      
      print("")// 解决 \u{1B}[1A\u{1B}[K 终端回刷方案可能的抖动
      
      var index = 0
      while semaphore.wait(timeout: .now()) == .timedOut {
        print("\u{1B}[1A\u{1B}[K\((path != nil) ? "[\(path!)] ": "")Text Correct\(Array(repeating: ".", count: (index % 6) + 1).joined(separator: ""))")
        index += 1
        Thread.sleep(forTimeInterval: 0.5)
      }
      print("\u{1B}[1A\u{1B}[K>>>>>>>>>>>>>>>> \((path != nil) ? "[\(path!)] ": "")Text Correct Result >>>>>>>>>>>>>>>>")
      
      Task {
        if await _data.readResult().isEmpty {
          print("Congratulations, No Text Need Correct.")
        }
        
        for (first, last, errors) in await _data.readResult() {
          print("source: \(first)")
          print("target: \(last)")
          print("error: \(errors)")
          print("")
          try await Task.sleep(nanoseconds: 200000000)
        }
        semaphore.signal()
      }
      
      semaphore.wait()
      print("")
    }
  }
  
  struct Files: ParsableCommand {
    static var configuration = CommandConfiguration(abstract: "Parse Signal Sentence From Files.")
    
    @Argument(help: "the files path list by space", transform: { URL(filePath: $0) })
    var paths: [URL]
    
    @OptionGroup var option: Options
    
    mutating func run() throws {
      
      var filters: [URL] = []
      
      // check file exist
      _ = paths.map {
        guard let _ = hlvFileExistCheck($0) else {
          filters.append($0)
          return
        }
      }
      guard filters.isEmpty else {
        hlvexit(HLVError.fileNotExist(filters.map{ $0.path(percentEncoded: false) }))
      }
      
      // check file is text
      filters.removeAll()
      _ = paths.map {
        guard HLVFile.isText($0.path(percentEncoded: false), encoding: .utf8) else {
          filters.append($0)
          return
        }
      }
      guard filters.isEmpty else {
        hlvexit(HLVError.fileNotExist(filters.map{ $0.path(percentEncoded: false) }))
      }
      
      // start parse
      for path in paths {
        do {
          let file = try openFile(path.path(percentEncoded: false), encoding: .utf8)
          
          defer {
            file.close()
          }
          
          var raw = try file.read()
          
          if option.markdown {
            raw = (try? Down(markdownString: raw).toAttributedString([.hardBreaks]).string) ?? ""
          }
          
          Command.parseText(raw, correct:option.correct, zh:option.zh, path: path.path(percentEncoded: false), minWords: option.minWords)
        } catch {
          print(error)
        }
      }
    }
  }
  
  struct Folder: ParsableCommand {
    static var configuration = CommandConfiguration(abstract: "Parse Signal Sentence From Folder." )
    
    @Argument(help: "the files path list by space", transform: { URL(filePath: $0) })
    var folder: URL
    
    @OptionGroup var option: Options

    mutating func run() throws {
      guard let _ = hlvFileExistCheck(folder, isDirectory: true) else {
        hlvexit(HLVError.fileNotExist([folder.path()], isDirectory: true))
      }
      
      let paths = hlvSubFiles(folder.path(percentEncoded: false))
      guard !paths.isEmpty else {
        hlvexit(HLVError.custom("cannot find enough text file."))
      }
      
      // start parse
      for path in paths {
        do {
          let file = try openFile(path.path(percentEncoded: false), encoding: .utf8)
          
          defer {
            file.close()
          }
          
          var raw = try file.read()
          
          if option.markdown {
            raw = (try? Down(markdownString: raw).toAttributedString([.hardBreaks]).string) ?? ""
          }
          
          Command.parseText(raw, correct:option.correct, zh:option.zh, path: path.path(percentEncoded: false), minWords: option.minWords)
        } catch {
          print(error)
        }
      }
    }
  }
  
  struct Text: ParsableCommand {
    static var configuration = CommandConfiguration(abstract: "Parse Signal Sentence From Text." )
    
    @Argument(help: "the text to parse.")
    var text: String
    
    @OptionGroup var option: Options

    mutating func run() throws {
      var raw = text
      if option.markdown {
        raw = (try? Down(markdownString: raw).toAttributedString([.hardBreaks]).string) ?? ""
      }
      Command.parseText(raw, correct:option.correct, zh:option.zh, path: nil, minWords: option.minWords)
    }
  }
}

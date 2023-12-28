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

@main
struct Command: ParsableCommand {
  static var configuration = CommandConfiguration(
    abstract: "Parse Signal Sentence From Text Or File.",
    version: "1.0.0",
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

extension Command {
  
  static func parseText(_ text: String, path: String = "", minZhNum: UInt8 = 1) {
    _ = HLVParseInit.default
    
    let r = HLVParse.parseZh(text, minZhNum: minZhNum)
    
    guard !r.isEmpty else {
      hlvexit(HLVError.custom("cannot find enough chinese words."))
    }
    if !path.isEmpty, r.count > 0 {
      print("\(path):")
    }
    for i in 0..<r.count {
      print("\(i): \(r[i])")
    }
    print("")
  }
  
  struct Files: ParsableCommand {
    static var configuration = CommandConfiguration(abstract: "Parse Signal Sentence From Files." )
    
    @Argument(help: "the files path list by space", transform: { URL(filePath: $0) })
    var paths: [URL]
    
    @Flag(name: .shortAndLong, help: "need parse markdown .")
    var markdown = false

    @Option(name: .shortAndLong, help: "the min chinese nums.")
    var numZh: UInt8 = 1
    
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
          
          if markdown {
            raw = (try? Down(markdownString: raw).toAttributedString([.hardBreaks]).string) ?? ""
          }
          
          Command.parseText(raw, path: path.path(percentEncoded: false), minZhNum: numZh)
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
    
    @Flag(name: .shortAndLong, help: "need parse markdown .")
    var markdown = false

    @Option(name: .shortAndLong, help: "the min chinese nums.")
    var numZh: UInt8 = 1
    
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
          
          if markdown {
            raw = (try? Down(markdownString: raw).toAttributedString([.hardBreaks]).string) ?? ""
          }
          
          Command.parseText(raw, path: path.path(percentEncoded: false), minZhNum: numZh)
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
    
    @Option(name: .shortAndLong, help: "the min chinese nums.")
    var numZh: UInt8 = 1
    
    mutating func run() throws {
      Command.parseText(text, minZhNum: numZh)
    }
  }
}

//
//  File.swift
//  
//
//  Created by gebiwanger on 2023/12/22.
//

import Foundation
import HLVFileDump

let Files = FileManager.default

// MARK: - Open File

public func openFile(_ path: String, encoding: String.Encoding = .utf8) throws -> HLVFile {
  return try HLVFile(path, encoding: encoding)
}

public func openFile(_ path: URL, encoding: String.Encoding = .utf8) throws -> HLVFile {
  return try HLVFile(path.path(percentEncoded: false), encoding: encoding)
}

// MARK: - File Exist Check

public func hlvFileExistCheck(_ path: URL, isDirectory: Bool = false) -> URL? {
  let m = path.path(percentEncoded: false)
  return hlvFileExistCheck(m, isDirectory: isDirectory)
}

public func hlvFileExistCheck(_ path: String, isDirectory: Bool = false) -> URL? {
  let fixedpath = NSString(string: path).standardizingPath
  let pathUrl = URL(filePath: fixedpath)
  
  var _isDirectory: ObjCBool = ObjCBool(isDirectory)
  
  // must exist
  guard Files.fileExists(atPath: pathUrl.path(percentEncoded: false), isDirectory: &_isDirectory) else {
    return nil
  }
  
  // file type isOk
  guard isDirectory == _isDirectory.boolValue else {
    return nil
  }
  
  return pathUrl
}

// MARK: - Sub Files

public func hlvSubFiles(_ path: String, encoding: String.Encoding = .utf8) -> [URL] {
  var subFiles: [URL] = []
  
  func traverse(folder: String) {
    do {
      let contents = try Files.contentsOfDirectory(at: URL(filePath: folder), includingPropertiesForKeys: [.isHiddenKey], options: .skipsHiddenFiles)
      for content in contents {
        let subpath = content.path(percentEncoded: false)
        var isDirectory: ObjCBool = false
        if Files.fileExists(atPath: subpath, isDirectory: &isDirectory) {
          if isDirectory.boolValue {
            traverse(folder: subpath)
          } else if HLVFileDump.HLVFile.isText(subpath, encoding: encoding) {
            subFiles.append(content)
          }
        }
      }
    } catch { }
  }
  
  traverse(folder: path)
  return subFiles
}

// MARK: - File Type Check

// MARK: - HLV File Object

public protocol HLVFileStream {
  var filehandle: FileHandle {get}
  var encoding: String.Encoding {get}
}

public struct HLVFile: HLVFileStream {
  public var filepath: String
  public var filehandle: FileHandle
  public var encoding: String.Encoding
  
  public typealias Convert = (String) -> String
  
  public init(_ path: String, encoding: String.Encoding) throws {
    guard let pathUrl = hlvFileExistCheck(path) else {
      throw HLVError.fileNotExist([path])
    }
    
    guard HLVFileDump.HLVFile.isText(path, encoding: encoding) else {
      throw HLVError.fileNotText([path])
    }
    
    do {
      self.filehandle = try FileHandle(forReadingFrom: pathUrl)
    } catch {
      throw HLVError.unknow
    }
    
    self.encoding = encoding
    self.filepath = path
  }
  
  public func close() {
    try? filehandle.close()
  }
  
  public func read() throws -> String {
    let data = self.filehandle.readDataToEndOfFile()

    guard let result = String(data: data, encoding: encoding), result.count > 0 else {
      throw HLVError.fileNotText([filepath])
    }
    
    return result
  }
  
}

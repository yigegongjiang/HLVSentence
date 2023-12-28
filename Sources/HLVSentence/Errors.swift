//
//  File.swift
//  
//
//  Created by gebiwanger on 2023/12/21.
//

import Foundation

public func hlvexit<T>(_ msg: T, _ code: Int = 1) -> Never {
  print(msg)
  exit(Int32(code))
}
  
public func hlvexit(_ error: Error) -> Never {
  guard let e = error as? HLVError else {
    hlvexit(error.localizedDescription, error._code)
  }
  hlvexit(e, e.code)
}

public enum HLVError: Error {
  case fileNotExist(_ path: [String], isDirectory: Bool = false)
  case fileNotText(_ path: [String])
  case custom(_ msg: String)
  case unknow
  
  var code: Int {
    1
  }
}

extension HLVError: CustomStringConvertible {
  public var description: String {
    switch self {
    case .fileNotExist(let m, isDirectory: let n):
      "[Error] \(n ? "[Directory]" : "[File]") Not Found For \"\(m.joined(separator: " & "))\"."
    case .fileNotText(let m):
      "[Error] [File] Not Found For \"\(m.joined(separator: " & "))\"."
    case .custom(let m):
      "[Error] \(m)"
    case .unknow:
      "Unknown error."
    }
  }
}

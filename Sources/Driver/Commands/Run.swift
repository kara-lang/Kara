//
//  Created by Max Desiatov on 02/10/2021.
//

import ArgumentParser
import Basic
import Foundation
import JSCodegen
import Syntax
import TypeChecker

public let driverPass = syntaxPass | typeCheckerPass | jsModuleFileCodegen

struct Run: ParsableCommand {
  @Argument(help: "The file to run.")
  var file: String

  func run() throws {
    let fileURL: URL
    if file.starts(with: "/") {
      fileURL = URL(fileURLWithPath: file)
    } else {
      let cwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
      fileURL = cwd.appendingPathComponent(file)
    }
    print(fileURL)

    let string = try String(contentsOf: fileURL)
    try print(driverPass(string))
  }
}

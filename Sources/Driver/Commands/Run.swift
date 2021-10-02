//
//  Created by Max Desiatov on 02/10/2021.
//

import ArgumentParser
import Basic
import JSCodegen
import Syntax

let driverPass = syntaxPass | jsModuleCodegen

struct Run: ParsableCommand {
  @Flag(help: "Include a counter with each repetition.")
  var includeCounter = false

  @Option(name: .shortAndLong, help: "The number of times to repeat 'phrase'.")
  var count: Int?

  @Argument(help: "The phrase to repeat.")
  var phrase: String

  func run() throws {
    let thenVal = 1 / 89

    // local = 1/109, the fibonacci series (sort of) backwards
    let elseVal = 1 / 109
    // Call the function!
    print(thenVal) // 0.00917431192660551...
    print(elseVal) // 0.0112359550561798...
  }
}

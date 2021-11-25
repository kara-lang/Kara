//
//  Created by Max Desiatov on 02/10/2021.
//

import ArgumentParser
import Driver

@main
public struct Kara: ParsableCommand {
  public static let configuration = CommandConfiguration(
    abstract: "Kara is a type-safe general purpose programming language.",
    version: karaVersion,
    subcommands: [Run.self, LSP.self]
  )

  public init() {}
}

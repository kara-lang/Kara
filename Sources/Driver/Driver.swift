//
//  Created by Max Desiatov on 02/10/2021.
//

import ArgumentParser

public struct Kara: ParsableCommand {
  public static let configuration = CommandConfiguration(
    abstract: "Kara is a type-safe general purpose programming language.",
    version: karaVersion,
    subcommands: [Run.self]
  )

  public init() {}
}

//
//  Created by Max Desiatov on 24/11/2021.
//

import ArgumentParser
import Foundation
import LSPServer

struct LSP: ParsableCommand {
  func run() throws {
    LSPConnection().run()
  }
}

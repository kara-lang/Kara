//
//  Created by Max Desiatov on 18/11/2021.
//

import Foundation
import LanguageServerProtocol
import LanguageServerProtocolJSONRPC

public final class LSPConnection {
  private let connection = JSONRPCConnection(
    protocol: .lspProtocol,
    inFD: FileHandle.standardInput,
    outFD: FileHandle.standardOutput
  )

  private let handler: MessageHandler

  public init() {
    handler = LanguageServer()
  }

  public func run() {
    connection.start(receiveHandler: handler)
    dispatchMain()
  }
}

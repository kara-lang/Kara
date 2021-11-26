//
//  Created by Max Desiatov on 26/11/2021.
//

import Foundation
import LanguageServerProtocol

extension DidOpenTextDocumentNotification: NotificationHandler {
  static var witness: NotificationHandlingWitness<Self> {
    .init(
      handle: { notification, server in
        let document = notification.textDocument
        await server.openDocument(uri: document.uri, text: document.text)
      }
    )
  }
}

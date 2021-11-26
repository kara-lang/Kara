//
//  Created by Max Desiatov on 25/11/2021.
//

import Foundation
import LanguageServerProtocol

extension LanguageServer: MessageHandler {
  func handle<Request>(
    _ params: Request,
    id: RequestID,
    from: ObjectIdentifier
  ) async -> LSPResult<Request.Response> where Request: RequestType {
    await params.handle(with: self)
  }

  func handle<Notification>(_: Notification, from: ObjectIdentifier) async where Notification: NotificationType {}
}

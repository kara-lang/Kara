//
//  Created by Max Desiatov on 26/11/2021.
//

import Foundation
import LanguageServerProtocol

struct NotificationHandlingWitness<Notification: NotificationType> {
  let handle: (Notification, LanguageServer) async -> ()

  func callAsFunction(_ notification: Notification, _ server: LanguageServer) async {
    await handle(notification, server)
  }
}

protocol NotificationHandler: NotificationType {
  static var witness: NotificationHandlingWitness<Self> { get }
}

extension NotificationHandler {
  static var anyWitness: Any { witness as Any }
}

private let notificationHandlingWitnesses: [String: Any] = [
  InitializeRequest.method: InitializeRequest.anyWitness,
]

extension NotificationType {
  func handle(with handler: MessageHandler) async {
    guard
      let witness = notificationHandlingWitnesses[Self.method] as? NotificationHandlingWitness<Self>,
      let server = handler as? LanguageServer
    else {
      return
    }

    await witness(self, server)
  }
}

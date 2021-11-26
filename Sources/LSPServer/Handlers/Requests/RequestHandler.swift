//
//  Created by Max Desiatov on 25/11/2021.
//

import Foundation
import LanguageServerProtocol

struct RequestHandlingWitness<Request: RequestType> {
  let handle: (Request, LanguageServer) async -> LSPResult<Request.Response>

  func callAsFunction(_ request: Request, _ server: LanguageServer) async -> LSPResult<Request.Response> {
    await handle(request, server)
  }
}

protocol RequestHandler: RequestType {
  static var witness: RequestHandlingWitness<Self> { get }
}

extension RequestHandler {
  static var anyWitness: Any { witness as Any }
}

private let requestHandlingWitnesses: [String: Any] = [
  InitializeRequest.method: InitializeRequest.anyWitness,
]

extension RequestType {
  func handle(with handler: MessageHandler) async -> LSPResult<Response> {
    guard
      let witness = requestHandlingWitnesses[Self.method] as? RequestHandlingWitness<Self>,
      let server = handler as? LanguageServer
    else {
      return .failure(ResponseError.methodNotFound(Self.method))
    }

    return await witness(self, server)
  }
}

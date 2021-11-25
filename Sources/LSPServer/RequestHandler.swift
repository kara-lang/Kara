//
//  Created by Max Desiatov on 25/11/2021.
//

import Foundation
import LanguageServerProtocol

public struct Handling<Request: RequestType> {
  let handle: (Request) async -> LSPResult<Request.Response>

  func callAsFunction(_ request: Request) async -> LSPResult<Request.Response> {
    await handle(request)
  }
}

public protocol RequestHandler: RequestType {
  static var witness: Handling<Self> { get }
}

public extension RequestHandler {
  static var anyWitness: Any { witness as Any }
}

let handlingWitnesses: [String: Any] = [
  InitializeRequest.method: InitializeRequest.anyWitness,
]

extension RequestType {
  func resolvedWitness() async -> LSPResult<Response> {
    guard let witness = handlingWitnesses[Self.method] as? Handling<Self> else {
      return .failure(ResponseError.methodNotFound(Self.method))
    }

    return await witness(self)
  }
}

//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2018 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import Dispatch
import LanguageServerProtocol
import LSPLogging

public typealias Notification = LanguageServerProtocol.Notification

/// An abstract language client or server.
actor LanguageServer {
  public struct RequestCancelKey: Hashable {
    public var client: ObjectIdentifier
    public var request: RequestID
    public init(client: ObjectIdentifier, request: RequestID) {
      self.client = client
      self.request = request
    }
  }

  /// The set of outstanding requests that may be cancelled.
  private var requestCancellation = [RequestCancelKey: CancellationToken]()

  /// Mapping from opened document URIs to their text content.
  private var documents = [DocumentURI: String]()

  /// Creates a language server for the given client.
  public init() {}

  func _logRequest<R>(_ request: Request<R>) {
    logAsync { currentLevel in
      guard currentLevel >= LogLevel.debug else {
        return "\(type(of: self)): Request<\(R.method)(\(request.id))>"
      }
      return "\(type(of: self)): \(request)"
    }
  }

  func _logNotification<N>(_ notification: Notification<N>) {
    logAsync { currentLevel in
      guard currentLevel >= LogLevel.debug else {
        return "\(type(of: self)): Notification<\(N.method)>"
      }
      return "\(type(of: self)): \(notification)"
    }
  }

  func _logResponse<Response>(_ result: LSPResult<Response>, id: RequestID, method: String) {
    logAsync { currentLevel in
      guard currentLevel >= LogLevel.debug else {
        return "\(type(of: self)): Response<\(method)(\(id))>"
      }
      return """
      \(type(of: self)): Response<\(method)(\(id))>(
        \(result)
      )
      """
    }
  }
}

/// Notification handlers
extension LanguageServer {
  func openDocument(uri: DocumentURI, text: String) {
    documents[uri] = text
  }
}

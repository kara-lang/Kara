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
  /// The server's request queue.
  ///
  /// All incoming requests start on this queue, but should reply or move to another queue as soon as possible to avoid blocking.
  public let queue = DispatchQueue(label: "language-server-queue", qos: .userInitiated)

  private var requestHandlers: [ObjectIdentifier: Any] = [:]

  private var notificationHandlers: [ObjectIdentifier: Any] = [:]

  public struct RequestCancelKey: Hashable {
    public var client: ObjectIdentifier
    public var request: RequestID
    public init(client: ObjectIdentifier, request: RequestID) {
      self.client = client
      self.request = request
    }
  }

  /// The set of outstanding requests that may be cancelled.
  private var requestCancellation: [RequestCancelKey: CancellationToken] = [:]

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

extension LanguageServer {
  // MARK: Request registration.

  /// Register the given request handler, which must be a method on `self`.
  ///
  /// Must be called on `queue`.
  public func _register<Server, R>(_ requestHandler: @escaping (Server) -> (Request<R>) -> ()) {
    // We can use `unowned` here because the handler is run synchronously on `queue`.
    precondition(self is Server)
    requestHandlers[ObjectIdentifier(R.self)] = { [unowned self] request in
      // swiftlint:disable:next force_cast
      requestHandler(self as! Server)(request)
    }
  }

  /// Register the given notification handler, which must be a method on `self`.
  ///
  /// Must be called on `queue`.
  public func _register<Server, N>(_ noteHandler: @escaping (Server) -> (Notification<N>) -> ()) {
    // We can use `unowned` here because the handler is run synchronously on `queue`.
    notificationHandlers[ObjectIdentifier(N.self)] = { [unowned self] note in
      // swiftlint:disable:next force_cast
      noteHandler(self as! Server)(note)
    }
  }

  /// Register the given request handler.
  ///
  /// Must be called on `queue`.
  public func _register<R>(_ requestHandler: @escaping (Request<R>) -> ()) {
    requestHandlers[ObjectIdentifier(R.self)] = requestHandler
  }

  /// Register the given notification handler.
  ///
  /// Must be called on `queue`.
  public func _register<N>(_ noteHandler: @escaping (Notification<N>) -> ()) {
    notificationHandlers[ObjectIdentifier(N.self)] = noteHandler
  }
}

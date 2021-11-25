//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2020 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import Dispatch

/// An abstract connection, allow messages to be sent to a (potentially remote) `MessageHandler`.
public protocol Connection: AnyObject {
  /// Send a notification without a reply.
  func send<Notification>(_: Notification) where Notification: NotificationType

  /// Send a request and (asynchronously) receive a reply.
  func send<Request>(_: Request, queue: DispatchQueue, reply: @escaping (LSPResult<Request.Response>) -> ())
    -> RequestID where Request: RequestType

  /// Send a request synchronously. **Use wisely**.
  func sendSync<Request>(_: Request) throws -> Request.Response where Request: RequestType
}

public extension Connection {
  func sendSync<Request>(_ request: Request) throws -> Request.Response where Request: RequestType {
    var result: LSPResult<Request.Response>?
    let semaphore = DispatchSemaphore(value: 0)
    _ = send(request, queue: DispatchQueue.global()) { _result in
      result = _result
      semaphore.signal()
    }
    semaphore.wait()
    return try result!.get()
  }
}

/// An abstract message handler, such as a language server or client.
public protocol MessageHandler: AnyObject {
  /// Handle a notification without a reply.
  func handle<Notification>(_: Notification, from: ObjectIdentifier) async where Notification: NotificationType

  /// Handle a request and (asynchronously) receive a reply.
  func handle<Request>(
    _: Request,
    id: RequestID,
    from: ObjectIdentifier
  ) async -> LSPResult<Request.Response> where Request: RequestType
}

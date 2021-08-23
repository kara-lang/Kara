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

/// A convenience wrapper for `Result` where the error is a `ResponseError`.
public typealias LSPResult<T> = Swift.Result<T, ResponseError>

/// Error code suitable for use between language server and client.
public struct ErrorCode: RawRepresentable, Codable, Hashable {
  public var rawValue: Int

  public init(rawValue: Int) {
    self.rawValue = rawValue
  }

  // JSON RPC
  public static let parseError = ErrorCode(rawValue: -32700)
  public static let invalidRequest = ErrorCode(rawValue: -32600)
  public static let methodNotFound = ErrorCode(rawValue: -32601)
  public static let invalidParams = ErrorCode(rawValue: -32602)
  public static let internalError = ErrorCode(rawValue: -32603)
  public static let serverErrorStart = ErrorCode(rawValue: -32099)
  public static let serverErrorEnd = ErrorCode(rawValue: -32000)
  public static let serverNotInitialized = ErrorCode(rawValue: -32002)
  public static let unknownErrorCode = ErrorCode(rawValue: -32001)

  // LSP
  public static let cancelled = ErrorCode(rawValue: -32800)
}

/// An error response represented by a code and message.
public struct ResponseError: Error, Codable, Hashable {
  public var code: ErrorCode
  public var message: String
  // FIXME: data

  public init(code: ErrorCode, message: String) {
    self.code = code
    self.message = message
  }
}

public extension ResponseError {
  // MARK: Convencience properties for common errors.

  static var cancelled = ResponseError(code: .cancelled, message: "request cancelled")

  static var serverNotInitialized = ResponseError(
    code: .serverNotInitialized,
    message: "received other request before \"initialize\""
  )

  static func methodNotFound(_ method: String) -> ResponseError {
    ResponseError(code: .methodNotFound, message: "method not found: \(method)")
  }

  static func unknown(_ message: String) -> ResponseError {
    ResponseError(code: .unknownErrorCode, message: message)
  }
}

/// An error during message decoding.
public struct MessageDecodingError: Error, Hashable {
  /// The error code.
  public var code: ErrorCode

  /// A free-form description of the error.
  public var message: String

  /// If it was possible to recover the request id, it is stored here. This can be used e.g. to reply with a `ResponseError` to invalid requests.
  public var id: RequestID?

  public enum MessageKind {
    case request
    case response
    case notification
    case unknown
  }

  /// What kind of message was being decoded, or `.unknown`.
  public var messageKind: MessageKind

  public init(code: ErrorCode, message: String, id: RequestID? = nil, messageKind: MessageKind = .unknown) {
    self.code = code
    self.message = message
    self.id = id
    self.messageKind = messageKind
  }
}

public extension MessageDecodingError {
  static func methodNotFound(_ method: String, id: RequestID? = nil,
                             messageKind: MessageKind = .unknown) -> MessageDecodingError
  {
    MessageDecodingError(
      code: .methodNotFound,
      message: "method not found: \(method)",
      id: id,
      messageKind: messageKind
    )
  }

  static func invalidRequest(_ reason: String, id: RequestID? = nil,
                             messageKind: MessageKind = .unknown) -> MessageDecodingError
  {
    MessageDecodingError(code: .invalidRequest, message: reason, id: id, messageKind: messageKind)
  }

  static func invalidParams(_ reason: String, id: RequestID? = nil,
                            messageKind: MessageKind = .unknown) -> MessageDecodingError
  {
    MessageDecodingError(code: .invalidParams, message: reason, id: id, messageKind: messageKind)
  }

  static func parseError(_ reason: String, id: RequestID? = nil,
                         messageKind: MessageKind = .unknown) -> MessageDecodingError
  {
    MessageDecodingError(code: .parseError, message: reason, id: id, messageKind: messageKind)
  }
}

public extension ResponseError {
  /// Converts a `MessageDecodingError` to a `ResponseError`.
  init(_ decodingError: MessageDecodingError) {
    self.init(code: decodingError.code, message: decodingError.message)
  }
}

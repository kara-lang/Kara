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

/// Request to initialize the language server.
///
/// This is the first request sent by the client, providing the server with the client's
/// capabilities, configuration options, and initial information about the current workspace. The
/// server replies with its own capabilities, which allows the two sides to agree about the set of
/// supported protocol methods and values.
///
/// - Parameters:
///   - processId: The process identifier (pid) of the client process.
///   - rootURI: The workspace URI, or nil if no workspace is open.
///   - initializationOptions: User-provided options.
///   - capabilities: The capabilities provided by the client editor.
///   - trace: Whether to enable tracing.
///   - workspaceFolders: The workspace folders configured, if the client supports multiple workspace
///     folders.
///
/// - Returns:
public struct InitializeRequest: RequestType, Hashable {
  public static let method: String = "initialize"
  public typealias Response = InitializeResult

  /// The process identifier (pid) of the process that started the LSP server, or nil if the server
  /// was started by e.g. a user shell and should not be monitored.
  ///
  /// If the client process dies, the server should exit.
  public var processId: Int?

  /// The workspace path, or nil if no workspace is open.
  ///
  /// - Note: deprecated in favour of `rootURI`.
  public var rootPath: String?

  /// The workspace URI, or nil if no workspace is open.
  ///
  /// Takes precedence over the deprecated `rootPath`.
  public var rootURI: DocumentURI?

  /// User-provided options.
  public var initializationOptions: LSPAny?

  /// The capabilities provided by the client editor.
  public var capabilities: ClientCapabilities

  public enum Tracing: String, Codable {
    case off
    case messages
    case verbose
  }

  /// Whether to enable tracing.
  public var trace: Tracing? = .off

  /// The workspace folders configured, if the client supports multiple workspace folders.
  public var workspaceFolders: [WorkspaceFolder]?

  public init(
    processId: Int? = nil,
    rootPath: String? = nil,
    rootURI: DocumentURI?,
    initializationOptions: LSPAny? = nil,
    capabilities: ClientCapabilities,
    trace: Tracing = .off,
    workspaceFolders: [WorkspaceFolder]?
  ) {
    self.processId = processId
    self.rootPath = rootPath
    self.rootURI = rootURI
    self.initializationOptions = initializationOptions
    self.capabilities = capabilities
    self.trace = trace
    self.workspaceFolders = workspaceFolders
  }
}

extension InitializeRequest: Codable {
  private enum CodingKeys: String, CodingKey {
    case processId
    case rootPath
    case rootURI = "rootUri"
    case initializationOptions
    case capabilities
    case trace
    case workspaceFolders
  }
}

/// The server capabilities returned from the initialize request.
public struct InitializeResult: ResponseType, Hashable {
  /// The capabilities of the language server.
  public var capabilities: ServerCapabilities

  public init(capabilities: ServerCapabilities) {
    self.capabilities = capabilities
  }
}

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

/// Request for code-completion items at the given document location.
///
/// The server may - or may not - filter and sort the results before returning them. If the server
/// performs server-side filtering, it should set the `isIncomplete` flag on the result. However,
/// since there are no particular rules specified for server-side filtering, the client likely will
/// want to perform its own filtering as well.
///
/// Servers that provide document highlights should set the `completionProvider` server capability.
///
/// - Parameters:
///   - textDocument: The document to perform completion in.
///   - position: The location to perform completion at.
///   - context: Optional code-completion context.
///   - sourcekitlspOptions: **(LSP Extension)** code-completion options for sourcekit-lsp.
///
/// - Returns: A list of completion items to complete the code at the given position.
public struct CompletionRequest: TextDocumentRequest, Hashable {
  public static let method: String = "textDocument/completion"
  public typealias Response = CompletionList

  public var textDocument: TextDocumentIdentifier

  public var position: Position

  public var context: CompletionContext?

  public var sourcekitlspOptions: SKCompletionOptions?

  public init(
    textDocument: TextDocumentIdentifier,
    position: Position,
    context: CompletionContext? = nil,
    sourcekitlspOptions: SKCompletionOptions? = nil
  ) {
    self.textDocument = textDocument
    self.position = position
    self.context = context
    self.sourcekitlspOptions = sourcekitlspOptions
  }
}

/// How a completion was triggered
public struct CompletionTriggerKind: RawRepresentable, Codable, Hashable {
  /// Completion was triggered by typing an identifier (24x7 code complete), manual invocation (e.g Ctrl+Space) or via API.
  public static let invoked = CompletionTriggerKind(rawValue: 1)

  /// Completion was triggered by a trigger character specified by the `triggerCharacters` properties of the `CompletionRegistrationOptions`.
  public static let triggerCharacter = CompletionTriggerKind(rawValue: 2)

  /// Completion was re-triggered as the current completion list is incomplete.
  public static let triggerFromIncompleteCompletions = CompletionTriggerKind(rawValue: 3)

  public let rawValue: Int
  public init(rawValue: Int) {
    self.rawValue = rawValue
  }
}

/// Contains additional information about the context in which a completion request is triggered.
public struct CompletionContext: Codable, Hashable {
  /// How the completion was triggered.
  public var triggerKind: CompletionTriggerKind

  /// The trigger character (a single character) that has trigger code complete. Is undefined if `triggerKind !== CompletionTriggerKind.TriggerCharacter`
  public var triggerCharacter: String?

  public init(triggerKind: CompletionTriggerKind, triggerCharacter: String? = nil) {
    self.triggerKind = triggerKind
    self.triggerCharacter = triggerCharacter
  }
}

/// List of completion items. If this list has been filtered already, the `isIncomplete` flag
/// indicates that the client should re-query code-completions if the filter text changes.
public struct CompletionList: ResponseType, Hashable {
  /// Whether the list of completions is "complete" or not.
  ///
  /// When this value is `true`, the client should re-query the server when doing further filtering.
  public var isIncomplete: Bool

  /// The resulting completions.
  public var items: [CompletionItem]

  public init(isIncomplete: Bool, items: [CompletionItem]) {
    self.isIncomplete = isIncomplete
    self.items = items
  }

  public init(from decoder: Decoder) throws {
    // Try decoding as CompletionList
    do {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      isIncomplete = try container.decode(Bool.self, forKey: .isIncomplete)
      items = try container.decode([CompletionItem].self, forKey: .items)
      return
    } catch {}

    // Try decoding as [CompletionItem]
    do {
      items = try [CompletionItem](from: decoder)
      isIncomplete = false
      return
    } catch {}

    let context = DecodingError.Context(
      codingPath: decoder.codingPath,
      debugDescription: "Expected CompletionList or [CompletionItem]"
    )
    throw DecodingError.dataCorrupted(context)
  }
}

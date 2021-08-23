//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2019 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

/// A workspace edit represents changes to many resources managed in the workspace.
public struct WorkspaceEdit: Hashable, ResponseType {
  /// The edits to be applied to existing resources.
  public var changes: [DocumentURI: [TextEdit]]?

  public var documentChanges: [WorkspaceEditDocumentChange]?

  public init(changes: [DocumentURI: [TextEdit]]? = nil,
              documentChanges: [WorkspaceEditDocumentChange]? = nil)
  {
    self.changes = changes
    self.documentChanges = documentChanges
  }
}

// Workaround for Codable not correctly encoding dictionaries whose keys aren't strings.
extension WorkspaceEdit: Codable {
  private enum CodingKeys: String, CodingKey {
    case changes
    case documentChanges
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    if let changesDict = try container.decodeIfPresent([String: [TextEdit]].self, forKey: .changes) {
      var changes = [DocumentURI: [TextEdit]]()
      for change in changesDict {
        let uri = DocumentURI(string: change.key)
        changes[uri] = change.value
      }
      self.changes = changes
    } else {
      changes = nil
    }
    documentChanges = try container.decodeIfPresent([WorkspaceEditDocumentChange].self, forKey: .documentChanges)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    if let changes = changes {
      var stringDictionary = [String: [TextEdit]]()
      for (key, value) in changes {
        stringDictionary[key.stringValue] = value
      }
      try container.encodeIfPresent(stringDictionary, forKey: .changes)
    }
    try container.encodeIfPresent(documentChanges, forKey: .documentChanges)
  }
}

public enum WorkspaceEditDocumentChange: Codable, Hashable {
  case textDocumentEdit(TextDocumentEdit)
  case createFile(CreateFile)
  case renameFile(RenameFile)
  case deleteFile(DeleteFile)

  public init(from decoder: Decoder) throws {
    if let edit = try? TextDocumentEdit(from: decoder) {
      self = .textDocumentEdit(edit)
    } else if let createFile = try? CreateFile(from: decoder) {
      self = .createFile(createFile)
    } else if let renameFile = try? RenameFile(from: decoder) {
      self = .renameFile(renameFile)
    } else if let deleteFile = try? DeleteFile(from: decoder) {
      self = .deleteFile(deleteFile)
    } else {
      let context = DecodingError.Context(
        codingPath: decoder.codingPath,
        debugDescription: "Expected TextDocumentEdit, CreateFile, RenameFile, or DeleteFile"
      )
      throw DecodingError.dataCorrupted(context)
    }
  }

  public func encode(to encoder: Encoder) throws {
    switch self {
    case let .textDocumentEdit(textDocumentEdit):
      try textDocumentEdit.encode(to: encoder)
    case let .createFile(createFile):
      try createFile.encode(to: encoder)
    case let .renameFile(renameFile):
      try renameFile.encode(to: encoder)
    case let .deleteFile(deleteFile):
      try deleteFile.encode(to: encoder)
    }
  }
}

/// Options to create a file.
public struct CreateFileOptions: Codable, Hashable {
  /// Overwrite existing file. Overwrite wins over `ignoreIfExists`
  public var overwrite: Bool?
  /// Ignore if exists.
  public var ignoreIfExists: Bool?

  public init(overwrite: Bool? = nil, ignoreIfExists: Bool? = nil) {
    self.overwrite = overwrite
    self.ignoreIfExists = ignoreIfExists
  }
}

/// Create file operation
public struct CreateFile: Codable, Hashable {
  /// The resource to create.
  public var uri: DocumentURI
  /// Additional options
  public var options: CreateFileOptions?

  public init(uri: DocumentURI, options: CreateFileOptions? = nil) {
    self.uri = uri
    self.options = options
  }

  // MARK: Codable conformance

  public enum CodingKeys: String, CodingKey {
    case kind
    case uri
    case options
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let kind = try container.decode(String.self, forKey: .kind)
    guard kind == "create" else {
      throw DecodingError.dataCorruptedError(
        forKey: .kind,
        in: container,
        debugDescription: "Kind of CreateFile is not 'create'"
      )
    }
    uri = try container.decode(DocumentURI.self, forKey: .uri)
    options = try container.decodeIfPresent(CreateFileOptions.self, forKey: .options)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode("create", forKey: .kind)
    try container.encode(uri, forKey: .uri)
    try container.encodeIfPresent(options, forKey: .options)
  }
}

/// Rename file options
public struct RenameFileOptions: Codable, Hashable {
  /// Overwrite target if existing. Overwrite wins over `ignoreIfExists`
  public var overwrite: Bool?
  /// Ignores if target exists.
  public var ignoreIfExists: Bool?

  public init(overwrite: Bool? = nil, ignoreIfExists: Bool? = nil) {
    self.overwrite = overwrite
    self.ignoreIfExists = ignoreIfExists
  }
}

/// Rename file operation
public struct RenameFile: Codable, Hashable {
  /// The old (existing) location.
  public var oldUri: DocumentURI
  /// The new location.
  public var newUri: DocumentURI
  /// Rename options.
  public var options: RenameFileOptions?

  public init(oldUri: DocumentURI, newUri: DocumentURI, options: RenameFileOptions? = nil) {
    self.oldUri = oldUri
    self.newUri = newUri
    self.options = options
  }

  // MARK: Codable conformance

  public enum CodingKeys: String, CodingKey {
    case kind
    case oldUri
    case newUri
    case options
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let kind = try container.decode(String.self, forKey: .kind)
    guard kind == "rename" else {
      throw DecodingError.dataCorruptedError(
        forKey: .kind,
        in: container,
        debugDescription: "Kind of RenameFile is not 'rename'"
      )
    }
    oldUri = try container.decode(DocumentURI.self, forKey: .oldUri)
    newUri = try container.decode(DocumentURI.self, forKey: .newUri)
    options = try container.decodeIfPresent(RenameFileOptions.self, forKey: .options)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode("rename", forKey: .kind)
    try container.encode(oldUri, forKey: .oldUri)
    try container.encode(newUri, forKey: .newUri)
    try container.encodeIfPresent(options, forKey: .options)
  }
}

/// Delete file options
public struct DeleteFileOptions: Codable, Hashable {
  /// Delete the content recursively if a folder is denoted.
  public var recursive: Bool?
  /// Ignore the operation if the file doesn't exist.
  public var ignoreIfNotExists: Bool?

  public init(recursive: Bool? = nil, ignoreIfNotExists: Bool? = nil) {
    self.recursive = recursive
    self.ignoreIfNotExists = ignoreIfNotExists
  }
}

/// Delete file operation
public struct DeleteFile: Codable, Hashable {
  /// The file to delete.
  public var uri: DocumentURI
  /// Delete options.
  public var options: DeleteFileOptions?

  public init(uri: DocumentURI, options: DeleteFileOptions? = nil) {
    self.uri = uri
    self.options = options
  }

  // MARK: Codable conformance

  public enum CodingKeys: String, CodingKey {
    case kind
    case uri
    case options
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let kind = try container.decode(String.self, forKey: .kind)
    guard kind == "delete" else {
      throw DecodingError.dataCorruptedError(
        forKey: .kind,
        in: container,
        debugDescription: "Kind of DeleteFile is not 'delete'"
      )
    }
    uri = try container.decode(DocumentURI.self, forKey: .uri)
    options = try container.decodeIfPresent(DeleteFileOptions.self, forKey: .options)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode("delete", forKey: .kind)
    try container.encode(uri, forKey: .uri)
    try container.encodeIfPresent(options, forKey: .options)
  }
}

extension WorkspaceEdit: LSPAnyCodable {
  public init?(fromLSPDictionary dictionary: [String: LSPAny]) {
    guard case let .dictionary(lspDict) = dictionary[CodingKeys.changes.stringValue] else {
      return nil
    }
    var dictionary = [DocumentURI: [TextEdit]]()
    for (key, value) in lspDict {
      let uri = DocumentURI(string: key)
      guard let edits = [TextEdit](fromLSPArray: value) else {
        return nil
      }
      dictionary[uri] = edits
    }
    changes = dictionary
  }

  public func encodeToLSPAny() -> LSPAny {
    guard let changes = changes else {
      return nil
    }
    let values = changes.map {
      ($0.key.stringValue, $0.value.encodeToLSPAny())
    }
    let dictionary = Dictionary(uniqueKeysWithValues: values)
    return .dictionary([
      CodingKeys.changes.stringValue: .dictionary(dictionary),
    ])
  }
}

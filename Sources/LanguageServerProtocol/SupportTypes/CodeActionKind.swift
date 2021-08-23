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

/// A code action kind.
///
/// In LSP, this is a string, so we don't use a closed set.
public struct CodeActionKind: RawRepresentable, Codable, Hashable {
  public var rawValue: String

  public init(rawValue: String) {
    self.rawValue = rawValue
  }

  /// QuickFix action, such as FixIt.
  public static let quickFix = CodeActionKind(rawValue: "quickfix")

  /// Base kind for refactoring action.
  public static let refactor = CodeActionKind(rawValue: "refactor")

  /// Base kind for refactoring extract action, such as extract method or extract variable.
  public static let refactorExtract = CodeActionKind(rawValue: "refactor.extract")

  /// Base kind for refactoring inline action, such as inline method, or inline variable.
  public static let refactorInline = CodeActionKind(rawValue: "refactor.inline")

  /// Refactoring rewrite action.
  // FIXME: what is this?
  public static let refactorRewrite = CodeActionKind(rawValue: "refactor.rewrite")

  /// Source action that applies to the entire file.
  // FIXME: what is this?
  public static let source = CodeActionKind(rawValue: "source")

  /// Organize imports action.
  public static let sourceOrganizeImports = CodeActionKind(rawValue: "source.organizeImports")
}

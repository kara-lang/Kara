//
//  Created by Max Desiatov on 03/10/2021.
//

import Basic
import Syntax

func typeCheck(module: ModuleFile) throws -> ModuleFile {
  var environment = Environment()
  var members = Members()

  for declaration in module.declarations.map(\.content.content) {
    switch declaration {
    case let .function(f):
      let identifier = f.identifier.content.content
      if environment[identifier] != nil {
        environment[identifier]?.append(f.scheme)
      } else {
        environment[identifier] = [f.scheme]
      }
    case let .binding(b):
      let identifier = b.identifier.content.content
      guard let scheme = b.scheme else {
        throw TypeError.topLevelAnnotationMissing(identifier)
      }

      guard environment[identifier] == nil else {
        throw TypeError.bindingDeclAlreadyExists(identifier)
      }

      environment[identifier] = [scheme]

    case let .struct(s):
      guard members[s.name.content] == nil else {
        throw TypeError.typeDeclAlreadyExists(s.name.content)
      }
      members[s.name.content] = [:]

    case .trait:
      continue
    }
  }

  return module
}

public let typeCheckerPass = CompilerPass { (module: ModuleFile) -> ModuleFile in
  // FIXME: detailed diagnostics
  // swiftlint:disable:next force_try
  try! typeCheck(module: module)
}

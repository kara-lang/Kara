//
//  Created by Max Desiatov on 03/10/2021.
//

import Basic
import Syntax

extension Declaration {
  func typeCheck(_ environment: ModuleEnvironment) throws {
    switch self {
    case let .function(f):
      guard let body = f.body else {
        throw TypeError.funcDeclBodyMissing(f.identifier.content.content)
      }

      var functionEnvironment = environment
      for parameter in f.parameters.elementsContent {
        functionEnvironment.insert(parameter)
      }

      let inferredReturnType = try Expr.block(body).infer(functionEnvironment)
      let expectedReturnType = f.returns?.content.content ?? .unit

      guard expectedReturnType == inferredReturnType else {
        throw TypeError.returnTypeMismatch(expected: expectedReturnType, actual: inferredReturnType)
      }

    case let .struct(s):
      try s.declarations.content.content.elements.map(\.content.content).forEach { try $0.typeCheck(environment) }

    default:
      return
    }
  }
}

extension ModuleFile {
  func typeCheck() throws {
    let environment = try environment

    try declarations.map(\.content.content).forEach { try $0.typeCheck(environment) }
  }
}

public let typeCheckerPass = CompilerPass { (module: ModuleFile) -> ModuleFile in
  // FIXME: detailed diagnostics
  // swiftlint:disable:next force_try
  try! module.typeCheck()
  return module
}

//
//  Created by Max Desiatov on 03/10/2021.
//

import Basic
import Syntax

extension FuncDecl {
  func typeCheck(_ environment: DeclEnvironment) throws {
    guard let body = body else {
      throw TypeError.funcDeclBodyMissing(identifier.content.content)
    }

    var functionEnvironment = environment
    for parameter in parameters.elementsContent {
      try environment.verifyContains(parameter.type.content.content)

      functionEnvironment.insert(parameter)
    }

    let inferredReturnType = try Expr.block(body).infer(functionEnvironment)
    let expectedReturnType = returns?.content.content ?? .unit

    guard expectedReturnType == inferredReturnType else {
      throw TypeError.returnTypeMismatch(expected: expectedReturnType, actual: inferredReturnType)
    }
  }
}

extension StructDecl {
  func typeCheck(_ environment: DeclEnvironment) throws {
    try declarations.content.content.elements.map(\.content.content).forEach { try $0.typeCheck(environment) }
  }
}

extension Declaration {
  func typeCheck(_ environment: DeclEnvironment) throws {
    switch self {
    case let .function(f):
      try f.typeCheck(environment)

    case let .struct(s):
      try s.typeCheck(environment)

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

public let typeCheckerPass = CompilerPass { (module: ModuleFile) throws -> ModuleFile in
  // FIXME: detailed diagnostics
  try module.typeCheck()
  return module
}

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

    // FIXME: possibly duplicate call to `parameterTypes`,
    // it's already called when inferring `Scheme` for this `FuncDecl` while collecting passed `DeclEnvironment`?
    let parameterSchemes = try parameterTypes(environment).map { (Expr?.none, Scheme($0)) }
    let parameters = parameters.elementsContent.map(\.internalName.content.content)
    functionEnvironment.insert(bindings: zip(parameters, parameterSchemes))

    let inferredType = try Expr.block(body).infer(functionEnvironment)
    let expectedType = try returnType(environment)

    guard expectedType == inferredType else {
      throw TypeError.typeMismatch(identifier.content.content, expected: expectedType, actual: inferredType)
    }
  }
}

extension StructDecl {
  func typeCheck(_ environment: DeclEnvironment) throws {
    try declarations.elements.map(\.content.content).forEach { try $0.typeCheck(environment) }
  }
}

extension BindingDecl {
  func typeCheck(_ environment: DeclEnvironment) throws {
    guard let value = value else { return }

    let inferredType = try value.expr.content.content.infer(environment)

    guard let expectedType = try type(environment) else { return }

    guard inferredType == expectedType else {
      throw TypeError.typeMismatch(identifier.content.content, expected: expectedType, actual: inferredType)
    }
  }
}

extension Declaration {
  func typeCheck(_ environment: DeclEnvironment) throws {
    switch self {
    case let .function(f):
      try f.typeCheck(environment)

    case let .struct(s):
      try s.typeCheck(environment)

    case let .binding(b):
      try b.typeCheck(environment)

    default:
      return
    }
  }
}

extension ModuleFile {
  func typeCheck() throws {
    let environment = try extend(DeclEnvironment())

    try declarations.map(\.content.content).forEach { try $0.typeCheck(environment) }
  }
}

public let typeCheckerPass = CompilerPass { (module: ModuleFile) throws -> ModuleFile in
  // FIXME: detailed diagnostics
  try module.typeCheck()
  return module
}

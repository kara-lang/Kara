//
//  Created by Max Desiatov on 03/10/2021.
//

import Basic
import Syntax

extension FuncDecl where A == EmptyAnnotation {
  func typeCheck(_ environment: ModuleEnvironment) throws {
    guard let body = body else {
      throw TypeError.funcDeclBodyMissing(identifier.content.content)
    }

    var functionEnvironment = environment

    // FIXME: possibly duplicate call to `parameterTypes`,
    // it's already called when inferring `Scheme` for this `FuncDecl` while collecting passed `DeclEnvironment`?
    let parameterSchemes = try parameterTypes(environment).map { (Expr<EmptyAnnotation>?.none, Scheme($0)) }
    let parameters = self.parameters.elementsContent.map(\.internalName.content.content)
    functionEnvironment.schemes.insert(bindings: zip(parameters, parameterSchemes))

    let inferredType = try Expr<EmptyAnnotation>(.block(body)).annotate(functionEnvironment).annotation
    let expectedType = try returnType(environment)

    guard expectedType == inferredType else {
      throw TypeError.typeMismatch(identifier.content.content, expected: expectedType, actual: inferredType)
    }
  }
}

extension StructDecl where A == EmptyAnnotation {
  func typeCheck(_ environment: ModuleEnvironment) throws {
    try declarations.elements.map(\.content.content).forEach { try $0.typeCheck(environment) }
  }
}

extension BindingDecl where A == EmptyAnnotation {
  func typeCheck(_ environment: ModuleEnvironment) throws {
    guard let value = value else { return }

    let inferredType = try value.expr.content.content.annotate(environment).annotation

    guard let expectedType = try type(environment) else { return }

    guard inferredType == expectedType else {
      throw TypeError.typeMismatch(identifier.content.content, expected: expectedType, actual: inferredType)
    }
  }
}

extension Declaration where A == EmptyAnnotation {
  func typeCheck(_ environment: ModuleEnvironment) throws {
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

extension ModuleFile where A == EmptyAnnotation {
  func typeCheck() throws {
    let environment = try ModuleEnvironment(self)

    try declarations.map(\.content.content).forEach { try $0.typeCheck(environment) }
  }
}

public let typeCheckerPass =
  CompilerPass { (module: ModuleFile<EmptyAnnotation>) throws -> ModuleFile<EmptyAnnotation> in
    // FIXME: detailed diagnostics
    try module.typeCheck()
    return module
  }

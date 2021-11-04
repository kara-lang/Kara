//
//  Created by Max Desiatov on 03/10/2021.
//

import Basic
import Syntax

extension FuncDecl where A == EmptyAnnotation {
  func typeCheck(_ environment: ModuleEnvironment<EmptyAnnotation>) throws -> FuncDecl<TypeAnnotation> {
    var functionEnvironment = environment

    // FIXME: this call to `parameterTypes` is possibly duplicate,
    // it's already called when inferring `Scheme` for this `FuncDecl` while collecting passed `DeclEnvironment`?
    let parameterSchemes = try parameterTypes(environment).map { (Expr<EmptyAnnotation>?.none, Scheme($0)) }
    let parameters = self.parameters.elementsContent.map(\.internalName.content.content)
    functionEnvironment.schemes.insert(bindings: zip(parameters, parameterSchemes))

    let annotated = try annotate(environment)

    guard let inferredType = try annotated.body?.getLastExprType() else {
      return annotated
    }

    let expectedType = try returnType(environment)

    guard expectedType == inferredType else {
      throw TypeError.typeMismatch(identifier.content.content, expected: expectedType, actual: inferredType)
    }

    return annotated
  }
}

extension BindingDecl where A == EmptyAnnotation {
  func typeCheck(_ environment: ModuleEnvironment<EmptyAnnotation>) throws -> BindingDecl<TypeAnnotation> {
    let annotated = try addAnnotation(
      typeSignature: { try $0.annotate(environment) },
      value: { try $0.annotate(environment) }
    )

    guard let inferredType = annotated.value?.expr.content.content.annotation else {
      return annotated
    }

    guard let expectedType = try type(environment) else { fatalError() }

    guard inferredType == expectedType else {
      throw TypeError.typeMismatch(identifier.content.content, expected: expectedType, actual: inferredType)
    }

    return annotated
  }
}

extension Declaration where A == EmptyAnnotation {
  func typeCheck(_ environment: ModuleEnvironment<EmptyAnnotation>) throws -> Declaration<TypeAnnotation> {
    switch self {
    case let .function(f):
      return try .function(f.typeCheck(environment))

    case let .struct(s):
      return try .struct(s.addAnnotation { try $0.typeCheck(environment) })

    case let .binding(b):
      return try .binding(b.typeCheck(environment))

    case let .enum(e):
      return try .enum(e.addAnnotation { try $0.typeCheck(environment) })

    case .trait, .enumCase:
      fatalError()
    }
  }
}

extension ModuleFile where A == EmptyAnnotation {
  func typeCheck() throws -> ModuleFile<TypeAnnotation> {
    let environment = try ModuleEnvironment(self)

    return try addAnnotation { try $0.typeCheck(environment) }
  }
}

public let typeCheckerPass =
  CompilerPass { (module: ModuleFile<EmptyAnnotation>) throws -> ModuleFile<TypeAnnotation> in
    // FIXME: detailed diagnostics
    try module.typeCheck()
  }

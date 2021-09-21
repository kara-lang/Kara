//
//  Created by Max Desiatov on 16/09/2021.
//

import Codegen
import Syntax

typealias JSCodegen<T> = CompilerPass<T, String>

let jsModuleCodegen = JSCodegen<ModuleFile> {
  $0.declarations.map(\.content.content).map(jsDeclarationCodegen.transform).joined(separator: "\n")
}

let jsDeclarationCodegen = JSCodegen<Declaration> {
  switch $0 {
  case let .function(f):
    return jsFunctionCodegen(f)
  default:
    fatalError()
  }
}

let jsFunctionCodegen = JSCodegen<FuncDecl> {
  """
  const \($0.identifier.value) =\
   (\($0.parameters.elementsContent.map(\.internalName))) => \(jsExprBlockCodegen($0.body));
  """
}

let jsExprBlockCodegen = JSCodegen<ExprBlock> {
  """
  {
      \($0.elements.map(\.content.content).map(jsExprBlockElementCodegen.transform).joined(separator: ";\n"))
  }
  """
}

let jsExprBlockElementCodegen = JSCodegen<ExprBlock.Element> {
  switch $0 {
  case let .expr(e):
    return jsExprCodegenTransform(e)
  case let .binding(b):
    return jsBindingCodegen(b)
  }
}

func jsExprCodegenTransform(_ input: Expr) -> String {
  switch input {
  case let .literal(.bool(b)):
    return "\(b)"
  case let .literal(.int32(i32)):
    return "\(i32)"
  case let .literal(.int64(i64)):
    return "\(i64)n"
  case let .literal(.double(d)):
    return "\(d)"
  case let .literal(.string(s)):
    return #""\#(s)""#
  case let .identifier(id):
    // FIXME: check for other keywords and predefined identifiers
    return id.value == "undefined" ? "undefined_" : id.value
  case let .application(a):
    return """
    \(jsExprCodegenTransform(a.function.content.content))\
    (\(a.arguments.elementsContent.map(jsExprCodegenTransform).joined(separator: ",")))
    """
  case let .closure(c):
    return
      """
      (\(c.parameters.map(\.identifier.content.content.value).joined(separator: ","))) =>
      \(jsExprCodegenTransform(c.body?.content.content ?? .unit));
      """
  case let .ifThenElse(ternary):
    return
      """
      (\(jsExprCodegenTransform(ternary.condition.content.content)) ?\
       \(jsExprCodegenTransform(ternary.thenBody.content.content)) :\
       \(jsExprCodegenTransform(ternary.elseBranch.elseBody.content.content)))
      """
  case let .member(m):
    return "\(jsExprCodegenTransform(m.base.content.content)).\(m.member.value)"
  case let .tuple(t):
    return "[\(t.elementsContent.map(jsExprCodegenTransform).joined(separator: ","))]"
  case .unit:
    return "undefined"
  }
}

let jsExprCodegen = JSCodegen(transform: jsExprCodegenTransform)

let jsBindingCodegen = JSCodegen<BindingDecl> {
  // FIXME: separate identifier codegen
  "const \($0.identifier.value) = \(jsExprCodegenTransform($0.value.content.content))"
}

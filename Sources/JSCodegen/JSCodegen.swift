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
  guard let body = $0.body else {
    // FIXME: Assert that interop modifier is present. Maybe we shouldn't reach this by checking for interop
    // modifier presence earlier?
    return ""
  }

  return """
  const \($0.identifier.value) =\
   (\($0.parameters.elementsContent.map(\.internalName))) => \(jsExprBlockCodegen(body));
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
  case let .ifThenElse(ifThenElse):
    guard let elseBlock = ifThenElse.elseBranch?.elseBlock else {
      return
        """
        if (\(jsExprCodegenTransform(ifThenElse.condition.content.content))) \
        \(jsExprBlockCodegen(ifThenElse.thenBlock))
        """
    }

    // FIXME: this is unlikely to work in blocks with multiple expressions
    return
      """
      (\(jsExprCodegenTransform(ifThenElse.condition.content.content)) ?\
       \(jsExprBlockCodegen(ifThenElse.thenBlock)) :\
       \(jsExprBlockCodegen(elseBlock)))
      """
  case let .member(m):
    return "\(jsExprCodegenTransform(m.base.content.content)).\(m.member.value)"
  case let .tuple(t):
    return "[\(t.elementsContent.map(jsExprCodegenTransform).joined(separator: ","))]"
  case let .block(block):
    return jsExprBlockCodegen(block)
  case .unit:
    return "undefined"
  }
}

let jsExprCodegen = JSCodegen(transform: jsExprCodegenTransform)

let jsBindingCodegen = JSCodegen<BindingDecl> {
  // FIXME: separate identifier codegen
  "const \($0.identifier.value) = \(jsExprCodegenTransform($0.value.content.content))"
}

//
//  Created by Max Desiatov on 16/09/2021.
//

import Basic
import Syntax

extension Bool {
  var not: Bool { !self }
}

// FIXME: use extensions on these Syntax types instead of the weird `JSCodegen` functions pattern
public typealias JSCodegen<T> = CompilerPass<T, String>

public let jsModuleFileCodegen = JSCodegen<ModuleFile> {
  $0.declarations.map(\.content.content).map(jsDeclarationCodegen.transform).filter(\.isEmpty.not)
    .joined(separator: "\n")
}

let jsDeclarationCodegen = JSCodegen<Declaration> {
  switch $0 {
  case let .function(f):
    return jsFuncDeclCodegen(f)
  case let .struct(s):
    // FIXME: handle structs with functions
    return ""

  case let .enum(e):
    // FIXME: handle enum cases and enums with functions
    return ""

  default:
    fatalError()
  }
}

let jsFuncDeclCodegen = JSCodegen<FuncDecl> {
  guard let body = $0.body else {
    // FIXME: Assert that interop modifier is present. Maybe we shouldn't reach this by checking for interop
    // modifier presence earlier?
    return ""
  }

  return """
  const \($0.identifier.value) =\
   (\(
     $0.parameters.elementsContent.map(\.internalName.value).joined(separator: ", ")
   )) => \(jsExprBlockCodegen(body));
  """
}

let jsExprBlockCodegen = JSCodegen<ExprBlock> {
  switch $0.elements.count {
  case 0:
    fatalError()
  case 1:
    return jsExprBlockElementCodegen($0.elements[0].content.content)
  default:
    return """
    {
      \($0.elements.map(\.content.content).map(jsExprBlockElementCodegen.transform).joined(separator: ";\n"))
    }
    """
  }
}

let jsIdentifierCodegen = JSCodegen<Identifier> {
  // FIXME: check for other keywords and predefined identifiers
  $0.value == "undefined" ? "undefined_" : $0.value
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
    return jsIdentifierCodegen(id)
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
  case let .block(b):
    return jsExprBlockCodegen(b)
  case let .type(t):
    return #"Symbol.for("Kara.\#(t.description)")"#
  case .unit:
    return "undefined"
  }
}

let jsExprCodegen = JSCodegen(transform: jsExprCodegenTransform)

let jsBindingCodegen = JSCodegen<BindingDecl> {
  // FIXME: separate identifier codegen
  "const \($0.identifier.value) = \(jsExprCodegenTransform($0.value.content.content))"
}

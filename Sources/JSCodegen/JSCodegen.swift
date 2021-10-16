//
//  Created by Max Desiatov on 16/09/2021.
//

import Basic
import Syntax

extension Bool {
  var not: Bool { !self }
}

public let jsModuleFileCodegen = CompilerPass<ModuleFile, String> {
  $0.declarations.map(\.jsCodegen).filter(\.isEmpty.not)
    .joined(separator: "\n")
}

extension Declaration {
  var jsCodegen: String {
    switch self {
    case let .function(f):
      return f.jsCodegen
    case .struct:
      // FIXME: handle structs with functions
      return ""

    case .enum:
      // FIXME: handle enum cases and enums with functions
      return ""

    default:
      fatalError()
    }
  }
}

extension FuncDecl {
  var jsCodegen: String {
    guard let body = body else {
      // FIXME: Assert that interop modifier is present. Maybe we shouldn't reach this by checking for interop
      // modifier presence earlier?
      return ""
    }

    return """
    const \(identifier.jsCodegen) =\
     (\(
       parameters.elementsContent.map(\.internalName.jsCodegen).joined(separator: ", ")
     )) => \(body.jsCodegen);
    """
  }
}

extension ExprBlock.Element {
  var jsCodegen: String {
    switch self {
    case let .expr(e):
      return e.jsCodegen
    case let .binding(b):
      return b.jsCodegen
    }
  }
}

extension ExprBlock {
  var jsCodegen: String {
    switch elements.count {
    case 0:
      fatalError()
    case 1:
      return elements[0].jsCodegen
    default:
      return """
      {
        \(elements.map(\.jsCodegen).joined(separator: ";\n"))
      }
      """
    }
  }
}

extension Identifier {
  var jsCodegen: String {
    // FIXME: check for other keywords and predefined identifiers
    value == "undefined" ? "undefined_" : value
  }
}

extension StructLiteral.Element {
  var jsCodegen: String {
    "\(property.jsCodegen): \(value.jsCodegen)"
  }
}

extension StructLiteral {
  var jsCodegen: String {
    "({ \(elements.elementsContent.map(\.jsCodegen).joined(separator: ", ")) })"
  }
}

extension Expr {
  var jsCodegen: String {
    switch self {
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
      return id.jsCodegen
    case let .application(a):
      return """
      \(a.function.jsCodegen)\
      (\(a.arguments.elementsContent.map(\.jsCodegen).joined(separator: ",")))
      """
    case let .closure(c):
      return
        """
        (\(c.parameters.map(\.identifier.jsCodegen).joined(separator: ","))) =>
        \(c.body?.jsCodegen ?? Expr.unit.jsCodegen);
        """
    case let .ifThenElse(ifThenElse):
      guard let elseBlock = ifThenElse.elseBranch?.elseBlock else {
        return
          """
          if (\(ifThenElse.condition.jsCodegen)) \
          \(ifThenElse.thenBlock.jsCodegen)
          """
      }

      // FIXME: this is unlikely to work in blocks with multiple expressions
      return
        """
        (\(ifThenElse.condition.jsCodegen) ?\
         \(ifThenElse.thenBlock.jsCodegen) :\
         \(elseBlock.jsCodegen))
        """
    case let .member(m):
      switch m.member.content.content {
      case let .identifier(identifier):
        return "\(m.base.jsCodegen).\(identifier.jsCodegen)"
      case let .tupleElement(index):
        return "\(m.base.jsCodegen)[\(index)]"
      }
    case let .tuple(t):
      return "[\(t.elementsContent.map(\.jsCodegen).joined(separator: ","))]"
    case let .block(b):
      return b.jsCodegen
    case let .structLiteral(s):
      return s.jsCodegen
    case let .type(t):
      // FIXME: specify module type here to avoid name collisions
      return #"Symbol.for("Kara.\#(t.description)")"#
    case .unit:
      return "undefined"
    }
  }
}

extension BindingDecl {
  var jsCodegen: String {
    var result = "const \(identifier.jsCodegen)"
    if let value = value {
      result.append(" = \(value.expr.jsCodegen));")
    } else {
      result.append(";")
    }

    return result
  }
}

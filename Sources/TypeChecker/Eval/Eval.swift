//
//  Created by Max Desiatov on 22/10/2021.
//

import Syntax

extension Type {
  func eval(_ environment: DeclEnvironment) -> NormalForm {
    switch self {
    case let .tuple(types):
      return .tuple(types.map { $0.eval(environment) })

    case let .arrow(head, tail):
      return .arrow(head.map { $0.eval(environment) }, tail.eval(environment))

    case let .constructor(id, args):
      return .typeConstructor(id, args.map { $0.eval(environment) })

    case .variable:
      fatalError()
    }
  }
}

extension Expr {
  func eval(_ environment: DeclEnvironment) throws -> NormalForm {
    switch self {
    case let .identifier(i):
      let result = try (
        environment.bindings[i]?.value ??
          environment.functions[i]?.body.flatMap(Expr.block)
      )?.eval(environment)

      if let result = result {
        return result
      } else if environment.types[i] != nil {
        return .typeConstructor(i, [])
      } else if i == "Type" {
        // FIXME: maybe "Type" should be present in `DeclEnvironment` instead of checking for it directly?
        return .typeConstructor("Type", [])
      } else {
        return .identifier(i)
      }

    case let .application(a):
      let arguments = a.arguments.elementsContent

      switch try a.function.content.content.eval(environment) {
      case let .closure(parameters, body):
        precondition(arguments.count == parameters.count)
        return try body.apply(
          .init(uniqueKeysWithValues: zip(parameters, arguments.map { try $0.eval(environment) }))
        )

      default:
        fatalError()
      }

    case let .closure(c):
      return try .closure(
        parameters: c.parameters.map(\.identifier.content.content),
        body: c.body.eval(environment)
      )

    case let .literal(l):
      return .literal(l)

    case let .ifThenElse(i):
      let thenBranch = try i.thenBlock.elements.eval(environment)
      let elseBranch = try i.elseBranch?.elseBlock.elements.eval(environment) ?? .tuple([])
      switch try i.condition.content.content.eval(environment) {
      case let .literal(.bool(condition)):
        return condition ? thenBranch : elseBranch

      case let .identifier(i):
        return .ifThenElse(condition: i, then: thenBranch, else: elseBranch)

      default:
        fatalError()
      }

    case let .member(m):
      return try m.eval(environment)

    case let .tuple(t):
      return try .tuple(t.elementsContent.map { try $0.eval(environment) })

    case let .block(b):
      return try b.elements.eval(environment)

    case let .structLiteral(s):
      switch try s.type.content.content.eval(environment) {
      case let .identifier(i):
        throw TypeError.unbound(i)
      case let .typeConstructor(i, _):
        return try .structLiteral(
          i,
          .init(
            uniqueKeysWithValues: s.elements.elementsContent.map {
              try ($0.property.content.content, $0.value.content.content.eval(environment))
            }
          )
        )

      default:
        fatalError()
      }

    case .unit:
      return .tuple([])
    }
  }
}

extension Array where Element == SyntaxNode<ExprBlock.Element> {
  func eval(_ environment: DeclEnvironment) throws -> NormalForm {
    var modifiedEnvironment = environment

    for (i, element) in enumerated() {
      switch element.content.content {
      case let .expr(e) where i == count - 1:
        return try e.eval(modifiedEnvironment)

      case let .declaration(d):
        try modifiedEnvironment.insert(d)

      default:
        fatalError()
      }
    }

    fatalError()
  }
}

extension MemberAccess {
  func eval(_ environment: DeclEnvironment) throws -> NormalForm {
    let base = try self.base.content.content.eval(environment)
    switch (base, member.content.content) {
    case let (.tuple(elements), .tupleElement(i)):
      return elements[i]

    case let (.structLiteral(_, args), .identifier(member)):
      return args[member]!

    default:
      fatalError()
    }
  }
}

extension Dictionary where Value == NormalForm {
  func apply(_ substitution: [Identifier: NormalForm]) -> Self {
    mapValues { $0.apply(substitution) }
  }
}

extension Array where Element == NormalForm {
  func apply(_ substitution: [Identifier: NormalForm]) -> Self {
    map { $0.apply(substitution) }
  }
}

extension NormalForm {
  func apply(_ substitution: [Identifier: NormalForm]) -> NormalForm {
    switch self {
    case let .identifier(i):
      // FIXME: shouldn't this throw an error?
      return substitution[i] ?? .identifier(i)

    case let .closure(parameters, body):
      // Exclude closure parameters from the substitution to support shadowing.
      var modifiedSubstitution = substitution
      for parameter in parameters {
        modifiedSubstitution[parameter] = nil
      }
      return body.apply(substitution)

    case let .literal(l):
      return .literal(l)

    case let .ifThenElse(condition, thenBranch, elseBranch):
      if case let .literal(.bool(condition)) = substitution[condition] {
        if condition {
          return thenBranch.apply(substitution)
        } else {
          return elseBranch.apply(substitution)
        }
      } else {
        fatalError()
      }

    case let .tuple(elements):
      return .tuple(elements.apply(substitution))

    case let .structLiteral(id, fields):
      return .structLiteral(id, fields.apply(substitution))

    case let .typeConstructor(id, args):
      return .typeConstructor(id, args.apply(substitution))

    case let .arrow(head, tail):
      return .arrow(head.apply(substitution), tail.apply(substitution))
    }
  }
}

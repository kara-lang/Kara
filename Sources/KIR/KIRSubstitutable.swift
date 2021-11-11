//
//  Created by Max Desiatov on 11/11/2021.
//

import Syntax

public typealias KIRSubstitution = [Identifier: KIRExpr]

protocol KIRSubstitutable {
  func apply(_ substitution: KIRSubstitution) -> Self
}

extension Dictionary: KIRSubstitutable where Value: KIRSubstitutable {
  func apply(_ substitution: KIRSubstitution) -> Self {
    mapValues { $0.apply(substitution) }
  }
}

extension Array where Element: KIRSubstitutable {
  func apply(_ substitution: KIRSubstitution) -> Self {
    map { $0.apply(substitution) }
  }
}

extension KIRExpr: KIRSubstitutable {
  public func apply(_ substitution: KIRSubstitution) -> Self {
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

    case let .memberAccess(base, member):
      switch (base.apply(substitution), member) {
      case let (.identifier(i), _):
        return .memberAccess(.identifier(i), member)
      case let (.structLiteral(_, fields), .identifier(field)):
        return fields[field]!
      case let (.tuple(elements), .tupleElement(index)):
        return elements[index]
      default:
        fatalError()
      }

    case let .application(function: function, arguments: arguments):
      return .application(function: function.apply(substitution), arguments: arguments.apply(substitution))

    case let .enumCase(type, tag, arguments):
      return .enumCase(type: type.apply(substitution), tag: tag, arguments: arguments.apply(substitution))

    case let .caseMatch(type: type, tag: tag, subject: subject):
      return .caseMatch(type: type.apply(substitution), tag: tag, subject: subject.apply(substitution))

    case let .block(b):
      return .block(b)
    }
  }
}

extension KIRDecl: KIRSubstitutable {
  public func apply(_ substitution: KIRSubstitution) -> Self {
    switch self {
    case let .binding(id, expr):
      return .binding(id, expr.apply(substitution))
    }
  }
}

extension KIRExprBlock: KIRSubstitutable {
  public func apply(_ substitution: KIRSubstitution) -> Self {
    .init(
      decls: decls.apply(substitution),
      expr: expr.apply(substitution)
    )
  }
}

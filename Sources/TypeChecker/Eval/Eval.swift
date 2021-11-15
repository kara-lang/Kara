//
//  Created by Max Desiatov on 22/10/2021.
//

import KIR
import Syntax

extension Type {
  func eval<A: Annotation>(_ environment: ModuleEnvironment<A>) -> KIRExpr {
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
  func eval(_ environment: ModuleEnvironment<A>) throws -> KIRExpr {
    switch payload {
    case let .identifier(i):
      if case let (binding?, _)? = environment.schemes.bindings[i] {
        return try binding.eval(environment)
      } else if case let (parameters, body?, _)? = environment.schemes.functions[i] {
        return try .closure(parameters: parameters, body: body.elements.eval(environment))
      } else if environment.types.contains(i) {
        return .typeConstructor(i, [])
      } else if i == "Type" {
        // FIXME: maybe "Type" should be present in `DeclEnvironment` instead of checking for it directly?
        return .typeConstructor("Type", [])
      } else {
        return .identifier(i)
      }

    case let .application(a):
      let function = try a.function.content.content.eval(environment)
      let arguments = try a.arguments.elementsContent.map { try $0.eval(environment) }
      switch function {
      case let .closure(parameters, body):
        precondition(arguments.count == parameters.count)
        return body.apply(
          .init(uniqueKeysWithValues: zip(parameters, arguments))
        )

      case let .enumCase(typeID, tag: tag, arguments: []):
        return .enumCase(typeID, tag: tag, arguments: arguments)

      case .enumCase:
        fatalError("`eval` can only apply unapplied enum cases.")

      default:
        return .application(function: function, arguments: arguments)
      }

    case let .closure(c):
      return try .closure(
        parameters: c.parameters.identifiers.map(\.content.content),
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
        return .ifThenElse(condition: .identifier(i), then: thenBranch, else: elseBranch)

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

    case let .leadingDot(l):
      let typeID: Identifier
      switch annotation as? TypeAnnotation {
      case let .constructor(constructorTypeID, _):
        typeID = constructorTypeID
      case let .arrow(_, .constructor(resultTypeID, _)):
        typeID = resultTypeID
      default:
        fatalError()
      }

      let memberID = l.member.content.content
      let staticMembers: SchemeEnvironment<A>
      if let structEnvironment = environment.types.structs[typeID] {
        staticMembers = structEnvironment.staticMembers
      } else if let enumEnvironment = environment.types.enums[typeID] {
        if let enumCase = enumEnvironment.enumCases[memberID] {
          return .enumCase(typeID, tag: enumCase.tag, arguments: [])
        } else {
          staticMembers = enumEnvironment.staticMembers
        }
      } else {
        fatalError()
      }

      if case let (parameters, body?, _)? = staticMembers.functions[memberID] {
        return try .closure(parameters: parameters, body: body.elements.eval(environment))
      } else if case let (value, _)? = staticMembers.bindings[memberID] {
        if let value = value {
          return try value.eval(environment)
        } else {
          return .memberAccess(.identifier(typeID), .identifier(memberID))
        }
      } else {
        fatalError()
      }

    case let .switch(s):
      let subject = try s.subject.content.content.eval(environment)
      let patterns = try s.caseBlocks.map(\.casePattern.pattern.content.content).map { try $0.eval(environment) }

      switch subject {
      case let .enumCase(typeID, tag: tag, arguments: _):
        guard
          environment.types.enums[typeID] != nil,
          let matchingCaseIndex = patterns.firstIndex(where: {
            switch $0 {
            case .enumCase(typeID, tag: tag, arguments: _):
              return true
            default:
              return false
            }
          })
        else {
          fatalError()
        }

        return try s.caseBlocks[matchingCaseIndex].exprBlock.elements.eval(environment)

      case .identifier:
        var result = KIRExpr.unreachable

        for i in stride(from: patterns.count - 1, to: -1, by: -1) {
          guard case let .enumCase(typeID, tag, _) = patterns[i] else {
            fatalError()
          }
          result = .ifThenElse(
            condition: .caseMatch(typeID, tag: tag, subject: subject),
            then: try s.caseBlocks[i].exprBlock.elements.eval(environment),
            else: result
          )
        }

        return result

      default:
        fatalError()
      }

    case .unit:
      return .tuple([])
    }
  }
}

extension Array {
  func eval<A>(_ environment: ModuleEnvironment<A>) throws -> KIRExpr
    where Element == SyntaxNode<ExprBlock<A>.Element>
  {
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
  func eval(_ environment: ModuleEnvironment<A>) throws -> KIRExpr {
    let base = try self.base.content.content.eval(environment)
    switch (base, member.content.content) {
    case let (.tuple(elements), .tupleElement(i)):
      return elements[i]

    case let (.structLiteral(typeID, args), .identifier(member)):
      if case let (parameters, body?, _)? = environment.types.structs[typeID]!.valueMembers.functions[member] {
        return try .closure(parameters: parameters, body: body.elements.eval(environment))
      } else {
        return args[member]!
      }

    case let (.identifier(id), member):
      return .memberAccess(.identifier(id), member)

    case let (.typeConstructor(typeID, _), .identifier(member)):
      let memberEnvironment: MemberEnvironment<A>
      if let structEnvironment = environment.types.structs[typeID] {
        memberEnvironment = structEnvironment.members
      } else if let enumEnvironment = environment.types.enums[typeID] {
        if let enumCase = enumEnvironment.enumCases[member] {
          return .enumCase(typeID, tag: enumCase.tag, arguments: [])
        }

        memberEnvironment = enumEnvironment.members
      } else {
        fatalError()
      }

      if case let (parameters, body?, _)? = memberEnvironment.staticMembers.functions[member] {
        return try .closure(parameters: parameters, body: body.elements.eval(environment))
      } else if case let (value?, _)? = memberEnvironment.staticMembers.bindings[member] {
        return try value.eval(environment)
      } else {
        fatalError()
      }

    default:
      fatalError()
    }
  }
}

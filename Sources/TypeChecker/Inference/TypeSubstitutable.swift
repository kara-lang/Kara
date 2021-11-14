//
//  Created by Max Desiatov on 27/04/2019.
//

import Syntax

typealias TypeSubstitution = [TypeVariable: Type]

extension TypeSubstitution {
  /// It is up to the implementation of the inference algorithm to ensure that
  /// clashes do not occur between substitutions.
  func compose(_ sub: TypeSubstitution) -> TypeSubstitution {
    sub.mapValues { $0.apply(self) }.merging(self) { value, _ in value }
  }
}

protocol TypeSubstitutable {
  func apply(_ sub: TypeSubstitution) -> Self
  var freeTypeVariables: Set<TypeVariable> { get }
}

extension TypeSubstitutable {
  func occurs(_ typeVariable: TypeVariable) -> Bool {
    freeTypeVariables.contains(typeVariable)
  }
}

extension TypeVariable: TypeSubstitutable {
  var freeTypeVariables: Set<TypeVariable> {
    [self]
  }

  func apply(_ sub: TypeSubstitution) -> TypeVariable {
    if case let .variable(v)? = sub[self] {
      return v
    } else {
      return self
    }
  }
}

extension Type: TypeSubstitutable {
  func apply(_ sub: TypeSubstitution) -> Type {
    switch self {
    case let .variable(v):
      return sub[v] ?? .variable(v)
    case let .arrow(t1, t2):
      return .arrow(t1.apply(sub), t2.apply(sub))
    case .constructor:
      return self
    case let .tuple(elements):
      return .tuple(elements.map { $0.apply(sub) })
    }
  }

  var freeTypeVariables: Set<TypeVariable> {
    switch self {
    case .constructor:
      return []
    case let .variable(v):
      return [v]
    case let .arrow(t1, t2):
      return t1.freeTypeVariables.union(t2.freeTypeVariables)
    case let .tuple(elements):
      return elements.freeTypeVariables
    }
  }
}

extension Scheme: TypeSubstitutable {
  func apply(_ sub: TypeSubstitution) -> Scheme {
    let type = self.type.apply(variables.reduce(sub) {
      var result = $0
      result[$1] = nil
      return result
    })
    return Scheme(type, variables: variables)
  }

  var freeTypeVariables: Set<TypeVariable> {
    type.freeTypeVariables.subtracting(variables)
  }
}

extension Array: TypeSubstitutable where Element: TypeSubstitutable {
  func apply(_ sub: TypeSubstitution) -> [Element] {
    map { $0.apply(sub) }
  }

  var freeTypeVariables: Set<TypeVariable> {
    reduce([]) { $0.union($1.freeTypeVariables) }
  }
}

extension Constraint: TypeSubstitutable {
  func apply(_ sub: TypeSubstitution) -> Constraint {
    switch self {
    case let .equal(t1, t2):
      return .equal(t1.apply(sub), t2.apply(sub))
    case let .member(type, member, mt):
      return .member(type.apply(sub), member: member, memberType: mt.apply(sub))
    case let .leadingDot(type, member):
      return .leadingDot(type.apply(sub), member: member)
    }
  }

  var freeTypeVariables: Set<TypeVariable> {
    switch self {
    case let .equal(t1, t2):
      return t1.freeTypeVariables.union(t2.freeTypeVariables)
    case let .member(type, _, memberType):
      return type.freeTypeVariables.union(memberType.freeTypeVariables)
    case let .leadingDot(type, _):
      return type.freeTypeVariables
    }
  }
}

extension ExprBlock: TypeSubstitutable where A == TypeAnnotation {
  func apply(_ sub: TypeSubstitution) -> ExprBlock<TypeAnnotation> {
    addAnnotation(expr: { $0.apply(sub) }, declaration: { $0.apply(sub) })
  }

  var freeTypeVariables: Set<TypeVariable> {
    elements.map(\.content.content).reduce(into: .init()) {
      switch $1 {
      case let .expr(e):
        return $0.formUnion(e.freeTypeVariables)
      case let .declaration(d):
        return $0.formUnion(d.freeTypeVariables)
      }
    }
  }
}

extension FuncApplication: TypeSubstitutable where A == TypeAnnotation {
  func apply(_ sub: TypeSubstitution) -> FuncApplication<TypeAnnotation> {
    addAnnotation(function: { $0.apply(sub) }, argument: { $0.apply(sub) })
  }

  var freeTypeVariables: Set<TypeVariable> {
    arguments.elementsContent.reduce(into: function.freeTypeVariables) {
      $0.formUnion($1.freeTypeVariables)
    }
  }
}

extension Closure: TypeSubstitutable where A == TypeAnnotation {
  func apply(_ sub: TypeSubstitution) -> Closure<TypeAnnotation> {
    addAnnotation(
      parameter: { $0.apply(sub) },
      body: { $0.apply(sub) }
    )
  }

  var freeTypeVariables: Set<TypeVariable> {
    parameters.typeSignatures.reduce(into: exprBlock.freeTypeVariables) {
      $0.formUnion($1.freeTypeVariables)
    }
  }
}

extension IfThenElse: TypeSubstitutable where A == TypeAnnotation {
  func apply(_ sub: TypeSubstitution) -> IfThenElse<Type> {
    addAnnotation(
      condition: { $0.apply(sub) },
      thenBlock: { $0.apply(sub) },
      elseBlock: { $0.apply(sub) }
    )
  }

  var freeTypeVariables: Set<TypeVariable> {
    var result = condition.freeTypeVariables

    result.formUnion(thenBlock.freeTypeVariables)
    if let elseBlock = elseBranch?.elseBlock {
      result.formUnion(elseBlock.freeTypeVariables)
    }
    return result
  }
}

extension MemberAccess: TypeSubstitutable where A == TypeAnnotation {
  func apply(_ sub: TypeSubstitution) -> MemberAccess<Type> {
    addAnnotation { $0.apply(sub) }
  }

  var freeTypeVariables: Set<TypeVariable> { base.freeTypeVariables }
}

extension DelimitedSequence: TypeSubstitutable where Content: TypeSubstitutable {
  func apply(_ sub: TypeSubstitution) -> DelimitedSequence<Content> {
    map { $0.apply(sub) }
  }

  var freeTypeVariables: Set<TypeVariable> {
    elementsContent.map(\.freeTypeVariables).reduce(into: Set()) {
      $0.formUnion($1)
    }
  }
}

extension StructLiteral: TypeSubstitutable where A == TypeAnnotation {
  func apply(_ sub: TypeSubstitution) -> StructLiteral<Type> {
    addAnnotation(
      type: { $0.apply(sub) },
      value: { $0.apply(sub) }
    )
  }

  var freeTypeVariables: Set<TypeVariable> {
    elements.elementsContent.map(\.value.freeTypeVariables).reduce(into: type.freeTypeVariables) {
      $0.formUnion($1)
    }
  }
}

extension Switch: TypeSubstitutable where A == TypeAnnotation {
  func apply(_ sub: TypeSubstitution) -> Switch<Type> {
    addAnnotation(
      subject: { $0.apply(sub) },
      caseBlock: {
        $0.addAnnotation(
          pattern: { $0.apply(sub) },
          body: { $0.apply(sub) }
        )
      }
    )
  }

  var freeTypeVariables: Set<TypeVariable> {
    caseBlocks.map(\.exprBlock.freeTypeVariables).reduce(into: subject.freeTypeVariables) {
      $0.formUnion($1)
    }
  }
}

extension Expr.Payload: TypeSubstitutable where A == TypeAnnotation {
  func apply(_ sub: TypeSubstitution) -> Expr<TypeAnnotation>.Payload {
    switch self {
    case .identifier, .leadingDot, .unit, .literal:
      return self
    case let .application(a):
      return .application(a.apply(sub))
    case let .closure(c):
      return .closure(c.apply(sub))
    case let .ifThenElse(i):
      return .ifThenElse(i.apply(sub))
    case let .member(m):
      return .member(m.apply(sub))
    case let .tuple(t):
      return .tuple(t.apply(sub))
    case let .block(b):
      return .block(b.apply(sub))
    case let .structLiteral(s):
      return .structLiteral(s.apply(sub))
    case let .switch(s):
      return .switch(s.apply(sub))
    }
  }

  var freeTypeVariables: Set<TypeVariable> {
    switch self {
    case .identifier, .literal, .unit, .leadingDot:
      return Set()
    case let .application(a):
      return a.freeTypeVariables
    case let .closure(c):
      return c.freeTypeVariables
    case let .ifThenElse(i):
      return i.freeTypeVariables
    case let .member(m):
      return m.freeTypeVariables
    case let .tuple(t):
      return t.freeTypeVariables
    case let .block(b):
      return b.freeTypeVariables
    case let .structLiteral(s):
      return s.freeTypeVariables
    case let .switch(s):
      return s.freeTypeVariables
    }
  }
}

extension Expr: TypeSubstitutable where A == TypeAnnotation {
  func apply(_ sub: TypeSubstitution) -> Expr<TypeAnnotation> {
    .init(payload: payload.apply(sub), annotation: annotation.apply(sub))
  }

  var freeTypeVariables: Set<TypeVariable> {
    annotation.freeTypeVariables
  }
}

extension BindingDecl: TypeSubstitutable where A == TypeAnnotation {
  func apply(_ sub: TypeSubstitution) -> BindingDecl<A> {
    addAnnotation(typeSignature: { $0.apply(sub) }, value: { $0.apply(sub) })
  }

  var freeTypeVariables: Set<TypeVariable> {
    typeSignature?.signature.freeTypeVariables ?? Set()
  }
}

extension FuncDecl.Parameter: TypeSubstitutable where A == TypeAnnotation {
  func apply(_ sub: TypeSubstitution) -> Self {
    addAnnotation { $0.apply(sub) }
  }

  var freeTypeVariables: Set<TypeVariable> {
    type.freeTypeVariables
  }
}

extension FuncDecl: TypeSubstitutable where A == TypeAnnotation {
  func apply(_ sub: TypeSubstitution) -> FuncDecl<A> {
    addAnnotation(
      parameterType: { $0.apply(sub) },
      arrow: { $0.apply(sub) },
      body: { $0.apply(sub) }
    )
  }

  var freeTypeVariables: Set<TypeVariable> {
    parameters.freeTypeVariables
      .union(arrow?.returns.freeTypeVariables ?? Set())
      .union(body?.freeTypeVariables ?? Set())
  }
}

extension DeclBlock: TypeSubstitutable where A == TypeAnnotation {
  func apply(_ sub: TypeSubstitution) -> DeclBlock<A> {
    addAnnotation { $0.apply(sub) }
  }

  var freeTypeVariables: Set<TypeVariable> {
    elements.reduce(into: Set()) {
      $0.formUnion($1.freeTypeVariables)
    }
  }
}

extension StructDecl: TypeSubstitutable where A == TypeAnnotation {
  func apply(_ sub: TypeSubstitution) -> StructDecl<A> {
    addAnnotation { $0.apply(sub) }
  }

  var freeTypeVariables: Set<TypeVariable> {
    declarations.freeTypeVariables
  }
}

extension EnumDecl: TypeSubstitutable where A == TypeAnnotation {
  func apply(_ sub: TypeSubstitution) -> EnumDecl<A> {
    addAnnotation { $0.apply(sub) }
  }

  var freeTypeVariables: Set<TypeVariable> {
    declarations.freeTypeVariables
  }
}

extension TraitDecl: TypeSubstitutable where A == TypeAnnotation {
  func apply(_ sub: TypeSubstitution) -> TraitDecl<A> {
    addAnnotation { $0.apply(sub) }
  }

  var freeTypeVariables: Set<TypeVariable> {
    declarations.freeTypeVariables
  }
}

extension EnumCase: TypeSubstitutable where A == TypeAnnotation {
  func apply(_ sub: TypeSubstitution) -> EnumCase<A> {
    addAnnotation { $0.apply(sub) }
  }

  var freeTypeVariables: Set<TypeVariable> {
    associatedValues?.elementsContent.reduce(into: Set()) {
      $0.formUnion($1.freeTypeVariables)
    } ?? Set()
  }
}

extension Declaration: TypeSubstitutable where A == TypeAnnotation {
  func apply(_ sub: TypeSubstitution) -> Declaration<Type> {
    switch self {
    case let .binding(b):
      return .binding(b.apply(sub))
    case let .function(f):
      return .function(f.apply(sub))
    case let .struct(s):
      return .struct(s.apply(sub))
    case let .enum(e):
      return .enum(e.apply(sub))
    case let .trait(t):
      return .trait(t.apply(sub))
    case let .enumCase(e):
      return .enumCase(e.apply(sub))
    }
  }

  var freeTypeVariables: Set<TypeVariable> {
    switch self {
    case let .binding(b):
      return b.freeTypeVariables
    case let .function(f):
      return f.freeTypeVariables
    case let .struct(s):
      return s.freeTypeVariables
    case let .enum(e):
      return e.freeTypeVariables
    case let .trait(t):
      return t.freeTypeVariables
    case let .enumCase(e):
      return e.freeTypeVariables
    }
  }
}

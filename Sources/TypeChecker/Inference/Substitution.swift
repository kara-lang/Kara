//
//  Created by Max Desiatov on 27/04/2019.
//

import Syntax

typealias Substitution = [TypeVariable: Type]

extension Substitution {
  /// It is up to the implementation of the inference algorithm to ensure that
  /// clashes do not occur between substitutions.
  func compose(_ sub: Substitution) -> Substitution {
    sub.mapValues { $0.apply(self) }.merging(self) { value, _ in value }
  }
}

protocol Substitutable {
  func apply(_ sub: Substitution) -> Self
  var freeTypeVariables: Set<TypeVariable> { get }
}

extension Substitutable {
  func occurs(_ typeVariable: TypeVariable) -> Bool {
    freeTypeVariables.contains(typeVariable)
  }
}

extension TypeVariable: Substitutable {
  var freeTypeVariables: Set<TypeVariable> {
    [self]
  }

  func apply(_ sub: Substitution) -> TypeVariable {
    if case let .variable(v)? = sub[self] {
      return v
    } else {
      return self
    }
  }
}

extension Type: Substitutable {
  func apply(_ sub: Substitution) -> Type {
    switch self {
    case let .variable(v):
      return sub[v] ?? .variable(v)
    case let .arrow(t1, t2):
      return t1.apply(sub) --> t2.apply(sub)
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

extension Scheme: Substitutable {
  func apply(_ sub: Substitution) -> Scheme {
    let type = type.apply(variables.reduce(sub) {
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

extension Array: Substitutable where Element: Substitutable {
  func apply(_ sub: Substitution) -> [Element] {
    map { $0.apply(sub) }
  }

  var freeTypeVariables: Set<TypeVariable> {
    reduce([]) { $0.union($1.freeTypeVariables) }
  }
}

extension BindingEnvironment: Substitutable {
  func apply(_ sub: Substitution) -> BindingEnvironment {
    mapValues { $0.apply(sub) }
  }

  var freeTypeVariables: Set<TypeVariable> {
    Array(values).freeTypeVariables
  }
}

extension Constraint: Substitutable {
  func apply(_ sub: Substitution) -> Constraint {
    switch self {
    case let .equal(t1, t2):
      return .equal(t1.apply(sub), t2.apply(sub))
    case let .member(type, member, mt):
      return .member(type.apply(sub), member: member, memberType: mt.apply(sub))
    }
  }

  var freeTypeVariables: Set<TypeVariable> {
    switch self {
    case let .equal(t1, t2):
      return t1.freeTypeVariables.union(t2.freeTypeVariables)
    case let .member(type, _, memberType):
      return type.freeTypeVariables.union(memberType.freeTypeVariables)
    }
  }
}

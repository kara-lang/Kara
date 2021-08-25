//
//  Created by Max Desiatov on 25/08/2021.
//

extension Inferred {
  func subst(_ i: Int, _ inferred: Inferred) -> Inferred {
    switch self {
    case let .annotation(c, c1):
      return .annotation(c.subst(i, inferred), c1.subst(i, inferred))

    case .star:
      return .star

    case let .pi(type, type1):
      return .pi(type.subst(i, inferred), type1.subst(i + 1, inferred))

    case let .bound(j):
      return i == j ? inferred : .bound(j)

    case let .free(y):
      return .free(y)

    case let .dollarOperator(inferred1, c):
      return .dollarOperator(inferred1.subst(i, inferred), c.subst(i, inferred))

    case .nat:
      return .nat

    case let .natElim(m, mz, ms, n):
      return .natElim(
        m.subst(i, inferred),
        mz.subst(i, inferred),
        ms.subst(i, inferred),
        n.subst(i, inferred)
      )

    case let .vec(a, n):
      return .vec(a.subst(i, inferred), n.subst(i, inferred))

    case let .vecElim(a, m, mn, mc, n, xs):
      return .vecElim(
        a.subst(i, inferred),
        m.subst(i, inferred),
        mn.subst(i, inferred),
        mc.subst(i, inferred),
        n.subst(i, inferred),
        xs.subst(i, inferred)
      )

    case let .eq(a, x, y):
      return .eq(a.subst(i, inferred), x.subst(i, inferred), y.subst(i, inferred))

    case let .eqElim(a, m, mr, x, y, eq):
      return .eqElim(
        a.subst(i, inferred),
        m.subst(i, inferred),
        mr.subst(i, inferred),
        x.subst(i, inferred),
        y.subst(i, inferred),
        eq.subst(i, inferred)
      )

    case let .fin(n):
      return .fin(n.subst(i, inferred))

    case let .finElim(m, mz, ms, n, f):
      return .finElim(
        m.subst(i, inferred),
        mz.subst(i, inferred),
        ms.subst(i, inferred),
        n.subst(i, inferred),
        f.subst(i, inferred)
      )
    }
  }
}

extension Checked {
  func subst(_ i: Int, _ inferred: Inferred) -> Checked {
    switch self {
    case let .inferred(inferred1):
      return .inferred(inferred1.subst(i, inferred))

    case let .lambda(c):
      return .lambda(c.subst(i + 1, inferred))

    case .zero:
      return .zero

    case let .succ(n):
      return n.subst(i, inferred)

    case let .nil(a):
      return .nil(a.subst(i, inferred))

    case let .cons(a, n, x, xs):
      return .cons(
        a.subst(i, inferred),
        n.subst(i, inferred),
        x.subst(i, inferred),
        xs.subst(i, inferred)
      )

    case let .refl(a, x):
      return .refl(a.subst(i, inferred), x.subst(i, inferred))

    case let .fZero(n):
      return .fZero(n.subst(i, inferred))

    case let .fSucc(n, k):
      return .fSucc(n.subst(i, inferred), k.subst(i, inferred))
    }
  }
}

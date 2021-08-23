//
//  Created by Max Desiatov on 23/08/2021.
//

extension Checked {
  func eval(_ names: NameEnv<Value>, _ environment: Env) -> Value {
    switch self {
    case let .inf(i):
      return i.eval(names, environment)

    case let .lambda(l):
      return .lambda { x in l.eval(names, environment + [x]) }

    case .zero:
      return .zero

    case let .succ(k):
      return .succ(k.eval(names, environment))

    case let .nil(a):
      return .nil(a.eval(names, environment))

    case let .cons(a, n, x, xs):
      return .cons(
        a.eval(names, environment),
        n.eval(names, environment),
        x.eval(names, environment),
        xs.eval(names, environment)
      )

    case let .refl(a, x):
      return .refl(
        a.eval(names, environment),
        x.eval(names, environment)
      )

    case let .fZero(n):
      return .fZero(n.eval(names, environment))

    case let .fSucc(n, f):
      return .fSucc(
        n.eval(names, environment),
        f.eval(names, environment)
      )
    }
  }
}

extension Inferred {
  func eval(_ names: NameEnv<Value>, _ environment: Env) -> Value {
    switch self {
    case let .ann(c, _):
      return c.eval(names, environment)

    case .star:
      return .star

    case let .pi(type, type1):
      return .pi(
        type.eval(names, environment),
        { x in type1.eval(names, environment + [x]) }
      )

    case let .free(x):
      if let v = names[x] {
        return v
      } else {
        return .free(x)
      }

    case let .bound(i):
      return environment[i]

    case let .dollarOperator(i, c):
      return i
        .eval(names, environment)
        .apply(c.eval(names, environment))

    case .nat:
      return .nat

    case let .natElim(m, mz, ms, n):
      let mzVal = mz.eval(names, environment)
      let msVal = ms.eval(names, environment)

      func rec(_ nVal: Value) -> Value {
        switch nVal {
        case .zero:
          return mzVal
        case let .succ(k):
          return msVal.apply(k).apply(rec(k))
        case let .neutral(n):
          return .neutral(
            .natElim(m.eval(names, environment), mzVal, msVal, n)
          )
        default:
          fatalError()
        }
      }

      return rec(n.eval(names, environment))
    }
  }
}

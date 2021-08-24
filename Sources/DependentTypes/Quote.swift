//
//  Created by Max Desiatov on 24/08/2021.
//

func quote(_ i: Int, _ value: Value) -> Checked {
  switch value {
  case let .lambda(t):
    return .lambda(quote(i + 1, t(.free(.quote(i)))))

  case .star:
    return .inferred(.star)

  case let .pi(v, f):
    return .inferred(.pi(quote(i, v), quote(i + 1, f(.free(.quote(i))))))

  case let .neutral(n):
    return .inferred(neutralQuote(i, n))

  case .nat:
    return .inferred(.nat)

  case .zero:
    return .zero

  case let .succ(n):
    return .succ(quote(i, n))

  case let .vec(a, n):
    return .inferred(.vec(quote(i, a), quote(i, n)))

  case let .nil(a):
    return .nil(quote(i, a))

  case let .cons(a, n, x, xs):
    return .cons(quote(i, a), quote(i, n), quote(i, x), quote(i, xs))

  case let .eq(a, x, y):
    return .inferred(.eq(quote(i, a), quote(i, x), quote(i, y)))

  case let .refl(a, x):
    return .refl(quote(i, a), quote(i, x))

  case let .fin(n):
    return .inferred(.fin(quote(i, n)))

  case let .fZero(n):
    return .fZero(quote(i, n))

  case let .fSucc(n, f):
    return .fSucc(quote(i, n), quote(i, f))
  }
}

private func neutralQuote(_ i: Int, _ neutral: Neutral) -> Inferred {
  switch neutral {
  case let .free(v):
    return boundFree(i, v)

  case let .app(n, v):
    return .dollarOperator(neutralQuote(i, n), quote(i, v))

  case let .natElim(m, z, s, n):
    return .natElim(quote(i, m), quote(i, z), quote(i, s), .inferred(neutralQuote(i, n)))

  case let .vecElim(a, m, mn, mc, n, xs):
    return .vecElim(
      quote(i, a),
      quote(i, m),
      quote(i, mn),
      quote(i, mc),
      quote(i, n),
      .inferred(neutralQuote(i, xs))
    )

  case let .eqElim(a, m, mr, x, y, eq):
    return .eqElim(
      quote(i, a),
      quote(i, m),
      quote(i, mr),
      quote(i, x),
      quote(i, y),
      .inferred(neutralQuote(i, eq))
    )

  case let .finElim(m, mz, ms, n, f):
    return .finElim(quote(i, m), quote(i, mz), quote(i, ms), quote(i, n), .inferred(neutralQuote(i, f)))
  }
}

private func boundFree(_ i: Int, _ name: Name) -> Inferred {
  if case let .quote(k) = name {
    return .bound(max(0, i - k - 1))
  } else {
    return .free(name)
  }
}

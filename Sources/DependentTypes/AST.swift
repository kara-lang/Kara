//
//  Created by Max Desiatov on 23/08/2021.
//

enum Name: Hashable {
  case global(String)
  case local(Int)
  case quote(Int)
}

indirect enum Checked {
  case inf(Inferred)
  case lambda(Checked)
  case zero
  case succ(Checked)
  case `nil`(Checked)
  case cons(Checked, Checked, Checked, Checked)
  case refl(Checked, Checked)
  case fZero(Checked)
  case fSucc(Checked, Checked)
}

indirect enum Inferred {
  case ann(Checked, Checked)
  case star
  case pi(Checked, Checked)
  case bound(Int)
  case free(Name)
  case dollarOperator(Inferred, Checked)
  case nat
  case natElim(Checked, Checked, Checked, Checked)
  case vec(Checked, Checked)
  case vecElim(Checked, Checked, Checked, Checked, Checked, Checked)
  case eq(Checked, Checked, Checked)
  case eqElim(Checked, Checked, Checked, Checked, Checked, Checked)
  case fin(Checked)
  case finElim(Checked, Checked, Checked, Checked, Checked)
}

indirect enum Value {
  case lambda((Value) -> Value)
  case star
  case pi(Value, (Value) -> Value)
  case neutral(Neutral)
  case nat
  case zero
  case succ(Value)
  case `nil`(Value)
  case cons(Value, Value, Value, Value)
  case vec(Value, Value)
  case eq(Value, Value, Value)
  case refl(Value, Value)
  case fZero(Value)
  case fSucc(Value, Value)
  case fin(Value)

  func apply(_ value: Value) -> Value {
    switch self {
    case let .lambda(f): return f(value)
    case let .neutral(n): return .neutral(.app(n, value))
    default: fatalError()
    }
  }

  static func free(_ name: Name) -> Value {
    .neutral(.free(name))
  }
}

indirect enum Neutral {
  case free(Name)
  case app(Neutral, Value)
  case natElim(Value, Value, Value, Neutral)
  case vecElim(Value, Value, Value, Value, Value, Neutral)
  case eqElim(Value, Value, Value, Value, Value, Neutral)
  case finElim(Value, Value, Value, Value, Neutral)
}

typealias Env = [Value]
typealias Type = Value
typealias Context = [Name: Type]
typealias NameEnv<V> = [Name: V]

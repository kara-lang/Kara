//
//  Created by Max Desiatov on 17/10/2021.
//

import CustomDump
@testable import Syntax
@testable import TypeChecker
import XCTest

final class EvalTests: XCTestCase {
  func testLiterals() throws {
    try assertEval("5", .literal(5))
    try assertEval("true", .literal(true))
  }

  func testClosures() throws {
    try assertEval("{ x in x }(42)", .literal(42))
    try assertEval("{ x, y in y }(0, 42)", .literal(42))
    try assertEval("{ x, y, z in if z { x } else { y }}(0, 42, false)", .literal(42))
    try assertEval("{ x, y in { x, y in x }(y, x)}(false, 42)", .literal(42))
    try assertEval("{ x, y in { x, y in { y, x in x }(x, y)}(y, x)}(false, 42)", .literal(false))
  }

  func testTuples() throws {
    try assertEval("(0, 42, false).1", .literal(42))
  }

  func testStructLiterals() throws {
    try assertEvalThrows("S {a: 0, b: 42, c: false}.b", TypeError.unbound("S"))
    try assertEval(
      """
      {
      struct Int32 {}
      enum Bool {}
      struct S {
        let a: Int32
        let b: Int32
        let c: Bool
      }
      S {a: 0, b: 42, c: false}.b
      }
      """,
      .closure(parameters: [], body: .literal(42))
    )
    try assertEval(
      """
      {
      struct Int32 {}
      enum Bool {}
      struct S {
        let a: Int32
        let b: Int32
        let c: Bool
      }
      S {a: 0, b: 42, c: false}.c
      }
      """,
      .closure(parameters: [], body: .literal(false))
    )
  }

  func testTypeAliases() throws {
    try assertEval(
      """
      {
      struct Int32 {}
      enum Bool {}
      struct S {
        let a: Int32
        let b: Int32
        let c: Bool
      }
      let SAlias: Type = S
      SAlias {a: 0, b: 42, c: false}.a
      }
      """,
      .closure(parameters: [], body: .literal(0))
    )
    try assertEval(
      """
      {
      struct Int32 {}
      enum Bool {}
      struct S {
        let a: Int32
        let b: Int32
        let c: Bool
      }
      func SAlias() -> Type { S }
      SAlias() {a: 0, b: 42, c: false}.a
      }
      """,
      .closure(parameters: [], body: .literal(0))
    )
    try assertEvalThrows(
      """
      {
      struct S {}
      let SAlias1: Type = S
      SAlias2 {a: 0, b: 42, c: false}.a
      }
      """,
      TypeError.unbound("SAlias2")
    )
  }

  func testMemberAccess() throws {
    try assertEval(
      """
      {
        struct Int {}
        struct S { let x: Int }
        func f(x: S) -> Int { x.x }
        f(S{x: 42})
      }
      """,
      .closure(parameters: [], body: .literal(42))
    )
  }

  func testEnvironmentCapture() throws {
    try assertEval(
      """
      {
        struct Int32 {}
        let x: Int32 = 42
        func f() -> Int32 { x }
        f()
      }
      """,
      .closure(parameters: [], body: .literal(42))
    )
  }

  func testMemberFunctions() throws {
    try assertEval(
      """
      {
        struct String {}
        enum Bool {}

        struct S {
          func f() -> String { "forty two" }

          static func f() -> String { "static" }
        }

        let s: S = S{}

        func f(condition: Bool) -> String {
          if condition {
            s.f()
          } else {
            S.f()
          }
        }

        f(false)
      }
      """,
      .closure(parameters: [], body: .literal("static"))
    )
  }

  func testLeadingDot() throws {
    try assertEval(
      """
      {
        enum Bool {}
        struct Int32 { static let max: Int32 = 2147483647 }
        func f(condition: Bool, x: Int32, y: Int32) {
          if condition { x } else { y }
        }

        (f(true, .max, 0), f(false, .max, 0))
      }
      """,
      .closure(parameters: [], body: .tuple([.literal(2_147_483_647), .literal(0)]))
    )
  }

  func testEnumCase() throws {
    try assertEval(
      """
      {
        struct Int32 {}
        enum E {
          case a
          case b(Int32)
        }
        let x: E = .a
        let y: E = .b(42)
        (x, y)
      }
      """,
      .closure(
        parameters: [],
        body: .tuple(
          [
            .enumCase("E", tag: 0, arguments: []),
            .enumCase("E", tag: 1, arguments: [.literal(42)]),
          ]
        )
      )
    )
  }

  func testSwitch() throws {
    try assertEval(
      """
      {
        struct Int32 {}
        struct String {}
        enum E {
          case a
          case b(Int32)
        }

        let x: String = switch E.a {
        case .a:
          "a"
        case .b:
          "b"
        }

        let y: String = switch E.b(42) {
        case .a:
          "a"
        case .b:
          "b"
        }

        (x, y)
      }
      """,
      .closure(parameters: [], body: .tuple([.literal("a"), .literal("b")]))
    )

    try assertEval(
      """
      {
        struct Int32 {}
        struct String {}
        enum E {
          case a
          case b(Int32)
        }

        { (x: E) in
          switch x {
            case .a:
              "a"
            case .b:
              "b"
          }
        }
      }
      """,
      .closure(
        parameters: [],
        body: .closure(
          parameters: ["x"],
          body: .ifThenElse(
            condition: .caseMatch("E", tag: 0, subject: .identifier("x")),
            then: .literal("a"),
            else: .ifThenElse(
              condition: .caseMatch("E", tag: 1, subject: .identifier("x")),
              then: .literal("b"),
              else: .unreachable
            )
          )
        )
      )
    )
  }
}

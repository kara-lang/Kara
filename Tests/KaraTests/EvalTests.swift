//
//  Created by Max Desiatov on 17/10/2021.
//

import CustomDump
@testable import Syntax
@testable import TypeChecker
import XCTest

final class EvalTests: XCTestCase {
  func testLiterals() {
    assertEval("5", .literal(5))
    assertEval("true", .literal(true))
  }

  func testClosures() {
    assertEval("{ x in x }(42)", .literal(42))
    assertEval("{ x, y in y }(0, 42)", .literal(42))
    assertEval("{ x, y, z in if z { x } else { y }}(0, 42, false)", .literal(42))
  }

  func testTuples() {
    assertEval("(0, 42, false).1", .literal(42))
  }

  func testStructLiterals() {
    assertEvalThrows("S [a: 0, b: 42, c: false].b", TypeError.unbound("S"))
    assertEval(
      """
      {
      struct S {}
      S [a: 0, b: 42, c: false].b
      }
      """,
      .closure(parameters: [], body: .literal(42))
    )
    assertEval(
      """
      {
      struct S {}
      S [a: 0, b: 42, c: false].c
      }
      """,
      .closure(parameters: [], body: .literal(false))
    )
  }

  func testTypeAliases() {
    assertEval(
      """
      {
      struct S {}
      let SAlias: Type = S
      SAlias [a: 0, b: 42, c: false].a
      }
      """,
      .closure(parameters: [], body: .literal(0))
    )
    assertEval(
      """
      {
      struct S {}
      func SAlias() -> Type { S }
      SAlias() [a: 0, b: 42, c: false].a
      }
      """,
      .closure(parameters: [], body: .literal(0))
    )
    assertEvalThrows(
      """
      {
      struct S {}
      let SAlias1: Type = S
      SAlias2 [a: 0, b: 42, c: false].a
      }
      """,
      TypeError.unbound("SAlias2")
    )
  }

  func testMemberAccess() {
    assertEval(
      """
      {
        struct Int {}
        struct S { let x: Int }
        func f(x: S) -> Int { x.x }
        f(S[x: 42])
      }
      """,
      .closure(parameters: [], body: .literal(42))
    )
  }

  func testEnvironmentCapture() {
    assertEval(
      """
      {
        struct Int {}
        let x: Int = 42
        func f() -> Int { x }
        f()
      }
      """,
      .closure(parameters: [], body: .literal(42))
    )
  }

  func testMemberFunctions() {
    assertEval(
      """
      {
        struct String {}
        enum Bool {}

        struct S {
          func f() -> String { "forty two" }

          static func f() -> String { "static" }
        }

        let s: S = S[]

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
}

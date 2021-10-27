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
}

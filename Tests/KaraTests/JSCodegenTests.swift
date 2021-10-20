//
//  Created by Max Desiatov on 01/10/2021.
//

@testable import Driver
import SnapshotTesting
import XCTest

final class JSCodegenTests: XCTestCase {
  func testFuncDecl() {
    // FIXME: `Bool` and `String` declarations should be picked up from stdlib
    assertJSSnapshot(
      """
      enum Bool {}
      struct String {}

      func f(condition: Bool) -> String {
          if condition {
              "true"
          } else {
              "false"
          }
      }
      """
    )

    assertJSSnapshot(
      """
      enum Bool {}
      struct String {}
      let StringAlias: Type = String

      func f(condition: Bool) -> StringAlias {
          if condition {
              "true"
          } else {
              "false"
          }
      }
      """
    )
  }

  func testTypeFuncDecl() {
    // FIXME: `Bool`, `String`, and `Int` declarations should be picked up from stdlib
    assertJSSnapshot(
      """
      enum Bool {}
      struct String {}
      struct Int {}

      func stringOrInt(x: Bool) -> Type {
          if x {
              String
          } else {
              Int
          }
      }
      """
    )
  }

  func testStructDecl() {
    // FIXME: `Int` declaration should be picked up from stdlib

    assertJSSnapshot(
      """
      struct Int {}

      struct Size {
          let width: Int
          let height: Int

          func multiply(x: Int, y: Int) -> Int { x }
      }
      """
    )
  }

  func testStructLiteral() {
    assertJSSnapshot(
      """
      struct S { let a: Int }

      func f() -> S {
          S [a: 42]
      }
      """
    )
  }

  func testTuple() {
    assertJSSnapshot(
      """
      func f() -> (Int32, String, Bool) {
          (42, "foo", false)
      }

      func f1() -> Int32 {
          f().0
      }
      """
    )
  }
}

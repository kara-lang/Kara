//
//  Created by Max Desiatov on 01/10/2021.
//

@testable import Driver
import SnapshotTesting
import XCTest

final class JSCodegenTests: XCTestCase {
  func testFuncDecl() throws {
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
  }

  func testTypeFuncDecl() throws {
    // FIXME: `Bool` declaration should be picked up from stdlib
    assertJSSnapshot(
      """
      enum Bool {}

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
}

//
//  Created by Max Desiatov on 01/10/2021.
//

@testable import Driver
import SnapshotTesting
import XCTest

final class JSCodegenTests: XCTestCase {
  func testFuncDecl() throws {
    assertJSSnapshot(
      """
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
    assertJSSnapshot(
      """
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

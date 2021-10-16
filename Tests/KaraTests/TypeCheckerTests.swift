//
//  Created by Max Desiatov on 14/10/2021.
//

@testable import Driver
@testable import Syntax
@testable import TypeChecker
import XCTest

final class TypeCheckerTests: XCTestCase {
  func testConflictingDeclarations() {
    assertError(
      try driverPass(
        """
        let x: Int = 5
        let x: Bool = false
        """
      ),
      TypeError.bindingDeclAlreadyExists("x")
    )
    assertError(
      try driverPass(
        """
        func f() {}
        func f() -> Int { 5 }
        """
      ),
      TypeError.funcDeclAlreadyExists("f")
    )
    assertError(
      try driverPass(
        """
        struct S {}
        struct S { let a: Int }
        """
      ),
      TypeError.typeDeclAlreadyExists("S")
    )
    assertError(
      try driverPass(
        """
        struct S {
        struct Inner {}
        struct Inner { let i: Int }
        }
        """
      ),
      TypeError.typeDeclAlreadyExists("Inner")
    )
    assertError(
      try driverPass(
        """
        enum E {}
        enum E { func f() {} }
        """
      ),
      TypeError.typeDeclAlreadyExists("E")
    )
  }

  func testFuncReturnType() {
    assertError(
      try driverPass(
        """
        func f() -> String { 42 }
        """
      ),
      TypeError.returnTypeMismatch(expected: .string, actual: .int32)
    )

    assertError(
      try driverPass(
        """
        func f() { 42 }
        """
      ),
      TypeError.returnTypeMismatch(expected: .unit, actual: .int32)
    )
  }

  func testTopLevelAnnotation() {
    assertError(
      try driverPass(
        """
        let x = 45
        """
      ),
      TypeError.topLevelAnnotationMissing("x")
    )

    assertError(
      try driverPass(
        """
        let x: Int32 = 45
        let y = true
        """
      ),
      TypeError.topLevelAnnotationMissing("y")
    )
  }

  func testTupleMembers() {
    assertError(
      try driverPass(
        """
        struct S {}

        let s: S = S[]
        let first: Int = s.0
        """
      ),
      TypeError.invalidStaticMember(.tupleElement(0))
    )

    assertError(
      try driverPass(
        """
        let first: Int32 = (42, false).5
        """
      ),
      TypeError.tupleIndexOutOfRange([.int32, .bool], addressed: 5)
    )
  }
}

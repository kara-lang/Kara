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
        struct Bool {}
        enum Bool {}
        """
      ),
      TypeError.typeDeclAlreadyExists("Bool")
    )
    assertError(
      try driverPass(
        """
        struct Int {}
        enum Bool {}

        let x: Int = 5
        let x: Bool = false
        """
      ),
      TypeError.bindingDeclAlreadyExists("x")
    )
    assertError(
      try driverPass(
        """
        struct Int {}

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
        struct Int {}

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
      TypeError.unbound("String")
    )

    assertError(
      try driverPass(
        """
        struct String {}

        func f() -> String { 42 }
        """
      ),
      TypeError.typeMismatch("f", expected: .string, actual: .int32)
    )

    assertError(
      try driverPass(
        """
        func f() { 42 }
        """
      ),
      TypeError.typeMismatch("f", expected: .unit, actual: .int32)
    )

    assertError(
      try driverPass(
        """
        func f() -> 42 { 42 }
        """
      ),
      TypeError.exprIsNotType(SourceRange(start: .init(column: 12, line: 0), end: .init(column: 13, line: 0)))
    )

    assertError(
      try driverPass(
        """
        enum Bool {}
        struct String {}
        let StringAlias1: Type = String

        func f(condition: Bool) -> StringAlias2 {
            if condition {
                "true"
            } else {
                "false"
            }
        }
        """
      ),
      TypeError.unbound("StringAlias2")
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
        struct Int32 {}

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
        struct Int {}

        let s: S = S{}
        let first: Int = s.0
        """
      ),
      TypeError.unknownMember(baseTypeID: "S", .tupleElement(0))
    )

    assertError(
      try driverPass(
        """
        struct Int32 {}

        let first: Int32 = (42, false).5
        """
      ),
      TypeError.tupleIndexOutOfRange([.int32, .bool], addressed: 5)
    )
  }
}

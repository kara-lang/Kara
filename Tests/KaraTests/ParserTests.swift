//
//  Created by Max Desiatov on 11/08/2021.
//

import CustomDump
import Parsing
import SnapshotTesting
@testable import Syntax
import XCTest

final class ParserTests: XCTestCase {
  func testLiterals() throws {
    XCTAssertNoDifference(literalParser.parse("123"), 123)
    XCTAssertNoDifference(literalParser.parse("true"), true)
    XCTAssertNoDifference(literalParser.parse("false"), false)
    XCTAssertNoDifference(literalParser.parse(#""string""#), "string")
    XCTAssertNoDifference(literalParser.parse("3.14"), 3.14)
  }

  func testStructs() throws {
    assertSnapshot(structParser.parse("struct Foo {}"))
    assertSnapshot(structParser.parse("struct  Bar{}"))

    assertSnapshot(structParser.parse("""
    struct
    Baz
    {
    }
    """))

    assertSnapshot(structParser.parse("""
    struct Foo
    {
      struct Bar {}
    }
    """))

    XCTAssertNil(structParser.parse("structBlorg{}").output)
  }

  func testIdentifiers() {
    XCTAssertNil(identifierParser.parse("123abc").output)
    assertSnapshot(identifierParser.parse("abc123"))
    assertSnapshot(identifierParser.parse("_abc123"))
    assertSnapshot(identifierParser.parse("/* hello! */abc123"))
    assertSnapshot(
      identifierParser.parse(
        """
        // test
        _abc123
        """
      )
    )
  }

  func testTuple() {
    XCTAssertNil(exprParser.parse("(,)").output)
    assertSnapshot(exprParser.parse("()"))
    assertSnapshot(exprParser.parse("(1 ,2 ,3 ,)"))
    assertSnapshot(exprParser.parse("(1,2,3,)"))
    assertSnapshot(exprParser.parse("(1,2,3)"))

    assertSnapshot(exprParser.parse("(1)"))
    assertSnapshot(exprParser.parse(#"("foo")"#))

    assertSnapshot(exprParser.parse(#"("foo", ("bar", "baz"))"#))
    assertSnapshot(exprParser.parse(#"("foo", ("bar", "baz", (1, "fizz")))"#))

    XCTAssertNil(exprParser.parse(#"("foo", ("bar", "baz", (1, "fizz"))"#).output)

    XCTAssertNil(exprParser.parse(#"("foo", ("bar")"#).output)
  }

  func testIfThenElse() {
    assertSnapshot(exprParser.parse(#"if true { "true" } else { "false" }"#))
    assertSnapshot(exprParser.parse(#"if foo { bar } else { baz }"#))
    assertSnapshot(
      exprParser.parse(
        #"""
        if 42.isInteger {
          "is integer"
        } else {
          "is not integer"
        }
        """#
      )
    )
    assertSnapshot(
      exprParser.parse(
        #"""
        if 42.isInteger() {
          "is integer"
        } else {
          "is not integer"
        }
        """#
      )
    )
  }

  func testClosure() {
    assertSnapshot(exprParser.parse("{}"))
    assertSnapshot(exprParser.parse("{ 1 }"))
    assertSnapshot(exprParser.parse("{1}"))
    assertSnapshot(exprParser.parse("{ x in 1 }"))
    assertSnapshot(exprParser.parse("{x in 1}"))
    assertSnapshot(exprParser.parse("{xin1}"))

    assertSnapshot(exprParser.parse("{ x, y, z in 1 }"))
    assertSnapshot(exprParser.parse("{ x,y,z in 1 }"))
    assertSnapshot(exprParser.parse("{x,y,z in 1}"))

    XCTAssertNil(exprParser.parse("{ x in y in 1 }").output)
    XCTAssertNil(exprParser.parse("{x in1}").output)
  }

  func testMemberAccess() {
    assertSnapshot(exprParser.parse("5.description"))
    assertSnapshot(exprParser.parse("5  .description"))
    assertSnapshot(
      exprParser.parse(
        """
        5
        .description
        """
      )
    )

    assertSnapshot(exprParser.parse("{x,y,z in 1}.description"))
    assertSnapshot(exprParser.parse("{x,y,z in 1}.description.description"))
    assertSnapshot(exprParser.parse("( 1 , 2, 3 ).description"))
    assertSnapshot(exprParser.parse("( 1, 2, 3 ).description"))
  }

  func testApplication() {
    assertSnapshot(exprParser.parse("{x,y,z in x}(1,2,3)"))
    assertSnapshot(exprParser.parse("{x,y,z in x} ( 1 , 2, 3 )"))
    assertSnapshot(exprParser.parse("{x,y,z in x} ( 1 , 2, 3 ).description"))
  }

  func testTypeConstructor() {
    assertSnapshot(typeParser.parse("Array<Int>"))
    assertNotFullyConsumed(typeParser.parse("Set<Double").rest)
    assertSnapshot(typeParser.parse("Dictionary <String, Bool>"))
    assertSnapshot(typeParser.parse("Result <String, IOError,>"))
    assertSnapshot(
      typeParser.parse(
        """
        Dictionary <String,
        Array<Bool>
        >
        """
      )
    )
  }

  func testTupleType() {
    assertSnapshot(typeParser.parse("(Int, Double, Bool)"))
    assertSnapshot(typeParser.parse("(Int, Double, Bool, String,)"))
    assertSnapshot(typeParser.parse("Array<(Int, String)>"))
    assertSnapshot(typeParser.parse("Array<(Int, String, Bool,)>"))
    assertSnapshot(typeParser.parse("Array<(Int, String, Bool,Dictionary<Double, Set<(Foo, Bar)>>)>"))
  }

  func testArrow() {
    assertSnapshot(typeParser.parse("Int -> Double"))
    assertSnapshot(typeParser.parse("Int -> Double -> String"))
    assertSnapshot(
      typeParser.parse(
        """
        Int ->
        Double ->
        String
        """
      )
    )
    assertSnapshot(typeParser.parse("(Int, Double) -> String"))
    assertSnapshot(typeParser.parse("Dictionary<Bool, (Int, Double, String)> -> Array<Character>"))
    assertSnapshot(typeParser.parse("Dictionary<Bool, (Int, Double, String)> -> (Array<Character>, Array<Bool>)"))
    assertNotFullyConsumed(typeParser.parse("Int -> ").rest)
    XCTAssertNil(typeParser.parse(" -> String").output)
  }

  func testFuncDecl() {
    assertSnapshot(funcDeclParser.parse("func f(x: Int) -> Int { x }"))
    assertSnapshot(funcDeclParser.parse(#"func f(x y: Bool) -> String { if y { "x" } else { "not x" } }"#))
    assertSnapshot(funcDeclParser.parse("private func f(x: Int) -> Int { x }"))
    assertSnapshot(funcDeclParser.parse(#"public func f(x y: Bool) -> String { if y { "x" } else { "not x" } }"#))
    assertSnapshot(funcDeclParser.parse("private public func f(x: Int) -> Int { x }"))
    assertSnapshot(
      funcDeclParser.parse(#"interop(JS, "fff") func f(x y: Bool) -> String"#)
    )
    assertSnapshot(
      funcDeclParser.parse(
        #"public interop(JS, "fff") func f(x y: Bool) -> String"#
      )
    )
  }

  func testTypeExpr() {
    assertSnapshot(exprParser.parse("Array"))
    assertSnapshot(exprParser.parse("Int32"))
  }
}

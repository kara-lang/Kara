//
//  Created by Max Desiatov on 11/08/2021.
//

import CustomDump
import Parsing
import SnapshotTesting
@testable import Syntax
import XCTest

extension Empty: CustomDumpStringConvertible {
  public var customDumpDescription: String { "()" }
}

extension SourceRange: CustomDumpStringConvertible {
  public var customDumpDescription: String {
    var result = ""
    customDump(content, to: &result)
    return "\(start.line):\(start.column)-\(end.line):\(end.column) \(result)"
  }
}

final class ParserTests: XCTestCase {
  func testNewline() {
    XCTAssertNil(newlineParser.parse("").output)
    XCTAssertNil(newlineParser.parse("foo").output)
    let parser = newlineParser.map { Substring($0.content) }
    XCTAssertEqual(parser.parse("\n").output, "\n")
    XCTAssertEqual(parser.parse("\r\n").output, "\r\n")
  }

  func testLiterals() throws {
    XCTAssertNoDifference(literalParser.parse("123"), 123)
    XCTAssertNoDifference(literalParser.parse("true"), true)
    XCTAssertNoDifference(literalParser.parse("false"), false)
    XCTAssertNoDifference(literalParser.parse(#""string""#), "string")
    XCTAssertNoDifference(literalParser.parse("3.14"), 3.14)
  }

  func testIdentifiers() {
    XCTAssertNil(identifierParser().parse("123abc").output)
    assertSnapshot(identifierParser().parse("abc123"))
    XCTAssertNil(identifierParser(requiresLeadingTrivia: true).parse("abc123").output)
    assertSnapshot(identifierParser().parse("_abc123"))
    assertSnapshot(identifierParser().parse("/* hello! */abc123"))
    assertSnapshot(
      identifierParser().parse(
        """
        // test
        _abc123
        """
      )
    )
  }

  func testTuple() {
    XCTAssertNil(exprParser().parse("(,)").output)
    assertSnapshot(exprParser().parse("()"))
    assertSnapshot(exprParser().parse("(1 ,2 ,3 ,)"))
    assertSnapshot(exprParser().parse("(1,2,3,)"))
    assertSnapshot(exprParser().parse("(1,2,3)"))

    assertSnapshot(exprParser().parse("(1)"))
    assertSnapshot(exprParser().parse(#"("foo")"#))

    assertSnapshot(exprParser().parse(#"("foo", ("bar", "baz"))"#))
    assertSnapshot(exprParser().parse(#"("foo", ("bar", "baz", (1, "fizz")))"#))

    XCTAssertNil(exprParser().parse(#"("foo", ("bar", "baz", (1, "fizz"))"#).output)

    XCTAssertNil(exprParser().parse(#"("foo", ("bar")"#).output)
  }

  func testIfThenElse() {
    assertSnapshot(exprParser().parse(#"if true { "true" } else { "false" }"#))
    assertSnapshot(exprParser().parse(#"if foo { bar } else { baz }"#))
    assertSnapshot(
      exprParser().parse(
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
      exprParser().parse(
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
    assertSnapshot(exprParser().parse("{}"))
    assertSnapshot(exprParser().parse("{ 1 }"))
    assertSnapshot(exprParser().parse("{1}"))
    assertSnapshot(exprParser().parse("{ x in 1 }"))
    assertSnapshot(exprParser().parse("{x in 1}"))
    assertSnapshot(exprParser().parse("{xin1}"))

    assertSnapshot(exprParser().parse("{ x, y, z in 1 }"))
    assertSnapshot(exprParser().parse("{ x,y,z in 1 }"))
    assertSnapshot(exprParser().parse("{x,y,z in 1}"))
    assertSnapshot(
      exprParser().parse(
        """
        {x,y,z in
            let a = sum(x, y, z)
            a
        }
        """
      )
    )
    assertSnapshot(
      exprParser().parse(
        """
        {
            f
            (1, 2, 3)
        }
        """
      )
    )
    assertSnapshot(
      exprParser().parse(
        """
        { (x, y: Bool, z) in
            z
            (1, 2, 3)
        }
        """
      )
    )

    XCTAssertNil(exprParser().parse("{ x in y in 1 }").output)
    XCTAssertNil(exprParser().parse("{x in1}").output)
  }

  func testMemberAccess() {
    assertSnapshot(exprParser().parse("5.description"))
    assertSnapshot(exprParser().parse("5  .description"))
    assertSnapshot(
      exprParser().parse(
        """
        5
        .description
        """
      )
    )

    assertSnapshot(exprParser().parse("{x,y,z in 1}.description"))
    assertSnapshot(exprParser().parse("{x,y,z in 1}.description.description"))
    assertSnapshot(exprParser().parse("( 1 , 2, 3 ).description"))
    assertSnapshot(exprParser().parse("( 1, 2, 3 ).description"))
  }

  func testTupleMembers() {
    assertSnapshot(exprParser().parse("a.1"))
    assertSnapshot(exprParser().parse("f().42"))
  }

  func testApplication() {
    assertSnapshot(exprParser().parse("{x,y,z in x}(1,2,3)"))
    assertSnapshot(exprParser().parse("{x,y,z in x} ( 1 , 2, 3 )"))
    assertSnapshot(exprParser().parse("{x,y,z in x} ( 1 , 2, 3 ).description"))
  }

  func testTypeExpr() {
    assertSnapshot(exprParser().parse("Array"))
    assertSnapshot(exprParser().parse("Int32"))
  }

  func testStructLiteral() {
    assertSnapshot(exprParser().parse(#"S {a: 5, b: true, c: "c"}"#))
    assertSnapshot(exprParser().parse(#"S {}"#))
    assertSnapshot(exprParser().parse(#"S{}"#))
    assertSnapshot(exprParser().parse(#"S/*foo*/{}"#))
  }

  func testLeadingDot() {
    assertSnapshot(exprParser().parse(".a"))
    assertSnapshot(exprParser().parse(".a.b.c"))
    assertSnapshot(exprParser().parse("./*foo*/a./*bar*/b/*baz*/.c"))
  }

  func testSwitch() {
    XCTAssertNil(exprParser().parse("switch {}").output)
    assertSnapshot(exprParser().parse("switch x {}"))
    assertSnapshot(
      exprParser().parse(
        """
        switch x{
        case true:
        case false:
        }
        """
      )
    )
    assertSnapshot(
      exprParser().parse(
        """
        switch/*switch comment*/y{
        case 1:
          "one"
        case 42:
          "forty two"
        }
        """
      )
    )

    assertSnapshot(
      exprParser().parse(
        """
        switch x.y.z {
        case let .binding(a, b):
          "a and b"
        case .anotherCase:
          "another case"
        }
        """
      )
    )
  }

  func testSwitchStructLiteral() {
    assertSnapshot(exprParser().parse("switch x {} {}"))
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
    assertSnapshot(
      funcDeclParser.parse(
        """
        func f(x: Int) -> Int {
          struct S {}
          x
        }
        """
      )
    )
    assertSnapshot(funcDeclParser.parse("static public func f(x: Int) -> Int { x }"))
  }

  func testGenericFuncDecl() {
    assertSnapshot(funcDeclParser.parse("func f<T>(x: T) -> T { x }"))
    assertSnapshot(funcDeclParser.parse("func f<T1, T2>(x: T1, y: T2) -> T1 { x }"))
    assertSnapshot(funcDeclParser.parse("func f<T1, T2 , T3 ,T4>(x: T1, y: T2) -> T1 { x }"))
    assertSnapshot(
      funcDeclParser.parse(
        """
        func f<T1, T2 , T3 ,T4>(x: T1, y: T2) -> T1 where T2 is P1 /* 1*/, T1 is P2 /* 2 */ , T3 /*3*/ is P3 {
          x
        }
        """
      )
    )
  }

  func testStructDecl() throws {
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

    assertSnapshot(structParser.parse("""
    struct StoredProperties {
      let a: Int    // `a` comment
      let b: Bool   // `b` comment
      let c: String // `c` comment
    }
    """))

    assertSnapshot(structParser.parse("""
    struct StoredProperties {
      struct Inner1 {
        let a: Double
      }
      let a: Int    // `a` comment
      let b: Bool   // `b` comment
      let c: String // `c` comment

      struct Inner2 {
        let a: Float
      }

      let inner1: Inner1
      let inner2: Inner2
    }
    """))
  }

  func testEnumDecl() {
    assertSnapshot(enumParser.parse("enum Foo {}"))
    assertSnapshot(enumParser.parse("enum  Bar{}"))

    assertSnapshot(enumParser.parse("""
    enum
    Baz
    {
    }
    """))

    assertSnapshot(enumParser.parse("""
    enum Foo
    {
      enum Bar {}
    }
    """))

    XCTAssertNil(enumParser.parse("enumBlorg{}").output)

    assertSnapshot(enumParser.parse("""
    enum Cases {
      case a    // `a` comment
      case b/*bb*/(Bool)   // `b` comment
      case c(Int/*c1*/,/*c2*/String) // `c` comment
    }
    """))

    assertSnapshot(enumParser.parse("""
    enum EnumWithMembers {
      struct Inner1 {
        let a: Double
      }
      case a    // `a` comment
      case b(Bool)   // `b` comment
      case c(Int, String) // `c` comment

      enum Inner2 {
        case a(Float)
      }

      func inner1() -> Inner1 { Inner1{a: 42.0} }
      func inner2() -> Inner2 { .a(42.0) }
    }
    """))
  }

  func testModuleFile() {
    assertSnapshot(
      moduleFileParser.parse(
        """
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
    )

    assertSnapshot(
      moduleFileParser.parse(
        """
        enum Bool {}

        func f(condition: Bool) -> Int { 42 }
        """
      )
    )
  }
}

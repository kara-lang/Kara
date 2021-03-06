//
//  Created by Max Desiatov on 18/08/2021.
//

import CustomDump
@testable import Syntax
@testable import TypeChecker
import XCTest

extension String {
  func inferParsedExpr(
    environment: ModuleEnvironment<EmptyAnnotation>
  ) throws -> Expr<TypeAnnotation> {
    var state = ParsingState(source: self)
    guard let expr = exprParser().parse(&state) else {
      throw ParsingError.unknown(startIndex..<endIndex)
    }

    return try expr.content.content.annotate(environment)
  }
}

infix operator -->

/// A shorthand version of `Type.arrow`
func --> (arguments: [Type], returned: Type) -> Type {
  Type.arrow(arguments, returned)
}

/// A shorthand version of `Type.arrow` for single argument functions
func --> (argument: Type, returned: Type) -> Type {
  Type.arrow([argument], returned)
}

final class SyntaxInferenceTests: XCTestCase {
  func testApplication() throws {
    let e = ModuleEnvironment<EmptyAnnotation>(
      schemes: .init(functions: [
        "increment": ([], nil, .init(.int32 --> .int32)),
        "stringify": ([], nil, .init(.int32 --> .string)),
      ])
    )

    try XCTAssertNoDifference("increment(0)".inferParsedExpr(environment: e).annotation, .int32)
    try XCTAssertNoDifference("stringify(0)".inferParsedExpr(environment: e).annotation, .string)
    XCTAssertThrowsError(try "increment(false)".inferParsedExpr(environment: ModuleEnvironment()))
    XCTAssertThrowsError(try "increment(false)".inferParsedExpr(environment: e))
  }

  func testClosure() throws {
    let e = ModuleEnvironment<EmptyAnnotation>(
      schemes: .init(functions: [
        "increment": ([], nil, .init(.int32 --> .int32)),
        "stringify": ([], nil, .init(.int32 --> .string)),
        "decode": ([], nil, .init(.string --> .int32)),
      ]),
      types: .init(structs: ["Int32": .init()])
    )

    XCTAssertNoDifference(
      try
        """
        { x in decode(stringify(increment(x))) }
        """
        .inferParsedExpr(environment: e).annotation, .int32 --> .int32
    )

    XCTAssertNoDifference(
      try
        """
        { (x: Int32) in x }
        """
        .inferParsedExpr(environment: e).annotation, .int32 --> .int32
    )

    assertError(
      try
        """
        { x in stringify(decode(increment(x))) }
        """.inferParsedExpr(environment: e),
      TypeError.unificationFailure(.string, .int32)
    )

    assertError(
      try exprParser().parse(
        """
        { x in stringify(decode(increment(x))) }
        """
      ).output?.content.content.annotate(ModuleEnvironment()),
      TypeError.unbound("stringify")
    )
  }

  func testClosureWithMultipleArguments() throws {
    let e = ModuleEnvironment<EmptyAnnotation>(
      schemes: .init(functions: [
        "sum": ([], nil, .init([.int32, .int32] --> .int32)),
        "stringify": ([], nil, .init([.int32, .int32] --> .string)),
        "decode": ([], nil, .init([.string, .string] --> .int32)),
      ])
    )

    XCTAssertNoDifference(
      try
        """
        { x, y in
          decode(
            stringify(
              sum(x,y),
              sum(x,y)
            ),
            stringify(
              sum(x,y),
              sum(x,y)
            )
          )
        }
        """.inferParsedExpr(environment: e).annotation, [.int32, .int32] --> .int32
    )
  }

  func testClosureWithMultipleArgumentsDifferentTypes() throws {
    let e = ModuleEnvironment<EmptyAnnotation>(
      schemes: .init(functions: [
        "concatenate": ([], nil, .init([.int32, .string] --> .string)),
        "sum": ([], nil, .init([.int32, .int32] --> .int32)),
        "decode": ([], nil, .init([.string, .int32] --> .int32)),
      ])
    )

    XCTAssertNoDifference(
      try
        """
        { str, int in
          decode(
            concatenate(int, str),
            sum(int, int)
          )
        }
        """.inferParsedExpr(environment: e).annotation,
      [.string, .int32] --> .int32
    )
  }

  func testMember() throws {
    let e = ModuleEnvironment<EmptyAnnotation>(
      types: .init(structs: [
        "String": .init(
          members: .init(
            valueMembers: .init(bindings: [
              "appending": (nil, .init(.string --> .string)),
              "count": (nil, .init(.int32)),
            ])
          )
        ),
      ])
    )

    XCTAssertNoDifference(
      try #""Hello, ".appending("World!")"#.inferParsedExpr(environment: e).annotation,
      .string
    )
    XCTAssertNoDifference(
      try #""Test".count"#.inferParsedExpr(environment: e).annotation,
      .int32
    )
    assertError(
      try #""Test".description"#.inferParsedExpr(environment: e).annotation,
      TypeError.unknownMember(baseTypeID: "String", .identifier("description"))
    )
  }

  func testMemberOfMember() throws {
    let e = ModuleEnvironment<EmptyAnnotation>(
      types: .init(structs: [
        "String": .init(
          members: .init(valueMembers: .init(bindings: [
            "count": (nil, .init(.int32)),
          ]))
        ),
        "Int32": .init(
          members: .init(valueMembers: .init(bindings: [
            "magnitude": (nil, .init(.int32)),
          ]))
        ),
      ])
    )

    XCTAssertNoDifference(
      try #""Test".count.magnitude"#.inferParsedExpr(environment: e).annotation,
      .int32
    )
    assertError(
      try #""Test".magnitude.count"#.inferParsedExpr(environment: e).annotation,
      TypeError.unknownMember(baseTypeID: "String", .identifier("magnitude"))
    )
  }

  func testIfThenElse() throws {
    let m = TypeEnvironment<EmptyAnnotation>(structs: [
      "Int32": .init(members: .init(valueMembers: .init(bindings: [
        "isInteger": (nil, .init(.bool)),
        "isIntegerFunc": (nil, .init([] --> .bool)),
        "toDouble": (nil, .init([] --> .double)),
      ]))),
    ])

    let e: SchemeEnvironment<EmptyAnnotation>.Bindings = [
      "foo": (nil, .init(.bool)),
      "bar": (nil, .init(.double)),
      "baz": (nil, .init(.double)),
      "fizz": (nil, .init(.int32)),
    ]

    XCTAssertNoDifference(
      try #"if true { "true" } else { "false" } "#.inferParsedExpr(environment: .init(types: m)).annotation,
      .string
    )
    XCTAssertNoDifference(
      try #"if foo { bar } else { baz }  "#
        .inferParsedExpr(environment: .init(schemes: .init(bindings: e), types: m)).annotation,
      .double
    )
    XCTAssertNoDifference(
      try
        #"""
        if 42.isInteger {
          "is integer"
        } else {
          "is not integer"
        }
        """#.inferParsedExpr(environment: .init(schemes: .init(bindings: e), types: m)).annotation,
      .string
    )
    XCTAssertNoDifference(
      try
        #"""
        if 42.isIntegerFunc() {
          "is integer"
        } else {
          "is not integer"
        }
        """#.inferParsedExpr(environment: .init(schemes: .init(bindings: e), types: m)).annotation,
      .string
    )
    assertError(
      try
        #"""
        if 42.toDouble() {
          "is integer"
        } else {
          "is not integer"
        }
        """#.inferParsedExpr(environment: .init(types: m)),
      TypeError.unificationFailure(.double, .bool)
    )
    assertError(
      try
        #"""
        if 42 {
          "is integer"
        } else {
          "is not integer"
        }
        """#.inferParsedExpr(environment: .init(types: m)),
      TypeError.unificationFailure(.int32, .bool)
    )
  }

  func testLeadingDot() throws {
    let t = TypeEnvironment<EmptyAnnotation>(
      structs: [
        "Int32": .init(members: .init(staticMembers: .init(bindings: [
          "max": (nil, .init(.int32)),
        ]))),
      ]
    )

    let e: SchemeEnvironment<EmptyAnnotation>.Bindings = [
      "stringify": (nil, .init(.int32 --> .string)),
    ]

    assertSnapshot(
      try #"stringify(.max)"#
        .inferParsedExpr(environment: .init(schemes: .init(bindings: e), types: t))
    )
  }

  func testSwitch() throws {
    let b: SchemeEnvironment<EmptyAnnotation>.Bindings = [
      "x": (nil, .init(.bool)),
      "y": (nil, .init(.int32)),
      "z": (nil, .init(.constructor("E", []))),
      "stringify": (nil, .init(.int32 --> .string)),
    ]

    let t = TypeEnvironment<EmptyAnnotation>(structs: ["Int32": .init(), "String": .init()])

    try assertSnapshot(
      """
      switch x{
      case true:
      case false:
      }
      """
      .inferParsedExpr(environment: .init(schemes: .init(bindings: b)))
    )

    try assertSnapshot(
      """
      switch/*switch comment*/y{
      case 1:
        "one"
      case 42:
        "forty two"
      }
      """
      .inferParsedExpr(environment: .init(schemes: .init(bindings: b)))
    )

    try assertSnapshot(
      """
      {
        enum E {
          case a(Int32)
          case b(String)
        }

        switch z {
        case let .a(i):
          stringify(i)
        case let .b(s):
          s
        }
      }
      """
      .inferParsedExpr(environment: .init(schemes: .init(bindings: b), types: t))
    )

    try assertSnapshot(
      """
      { x in
        switch x {
        case false:
          "false"
        case true:
          "true"
        }
      }
      """
      .inferParsedExpr(environment: .init())
    )

    try assertSnapshot(
      """
      {
        struct Int32 {}
        enum E {
          case a
          case b(Int32)
        }

        { x in
          switch x {
          case .a:
            "a"
          case .b:
            "b"
          }
        }
      }
      """
      .inferParsedExpr(environment: .init())
    )

    try assertError(
      """
      switch/*switch comment*/y{
      case false:
        "one"
      case 42:
        "forty two"
      }
      """
      .inferParsedExpr(environment: .init(schemes: .init(bindings: b))),
      TypeError.unificationFailure(.int32, .bool)
    )
  }

  func testEnumCase() throws {
    let e = ModuleEnvironment<EmptyAnnotation>(types: .init(structs: ["Int32": .init(), "String": .init()]))
    try assertSnapshot(
      """
      {
        enum E {
          case a
          case b(Int32)
        }
        (E.a, E.b(42), E.b)
      }
      """
      .inferParsedExpr(environment: e)
    )

    try assertSnapshot(
      """
      {
        enum E {
          case a
        }
        let x: E = .a
        x
      }
      """
      .inferParsedExpr(environment: e)
    )

    try assertError(
      """
      {
        enum E {
          case a
          case b(Int32)
        }
        E.c
      }
      """.inferParsedExpr(environment: e),
      TypeError.unknownStaticMember(baseTypeID: "E", .identifier("c"))
    )

    try assertError(
      """
      {
        struct E {
          case a
          case b(Int32)
        }
        E.c
      }
      """.inferParsedExpr(environment: e),
      TypeError.enumCaseOutsideOfEnum(
        .init(start: .init(column: 9, line: 2), end: .init(column: 9, line: 2), content: "a")
      )
    )
  }

  func testGenericFunction() throws {
    let e = ModuleEnvironment<EmptyAnnotation>()
    try assertSnapshot(
      """
      {
        func id<T>(x: T) -> T { x }
        id(5)
      }
      """
      .inferParsedExpr(environment: e)
    )
  }
}

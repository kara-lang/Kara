//
//  Created by Max Desiatov on 11/11/2021.
//

import Syntax

/** Intermediate in-memory representation of expressions. Compared to `enum Expr` in `Syntax` module, no syntactic
 information is stored here such as source location or trivia. Note that sometimes evaluation from `Expr` to `KIRExpr`
 can be only partial. For example, unapplied closures can't be fully evaluated without their arguments. Because of
 that we need to be able to represent unsubstituted identifiers within closure bodies with `KIRExpr`. That's why
 there are more cases in this `enum` than one would initially expect from complete evaluation of `Expr`.
 */
public enum KIRExpr: Hashable {
  case unreachable
  case identifier(Identifier)
  case literal(Literal)
  case tuple([KIRExpr])
  case structLiteral(Identifier, [Identifier: KIRExpr])
  case typeConstructor(Identifier, [KIRExpr])
  indirect case enumCase(Identifier, tag: Int, arguments: [KIRExpr])
  indirect case caseMatch(Identifier, tag: Int, subject: KIRExpr)
  indirect case application(function: KIRExpr, arguments: [KIRExpr])
  indirect case memberAccess(KIRExpr, Member)
  indirect case closure(parameters: [Identifier], body: KIRExpr)
  indirect case ifThenElse(condition: KIRExpr, then: KIRExpr, else: KIRExpr)
  indirect case arrow([KIRExpr], KIRExpr)
  indirect case block(KIRExprBlock)
}

public enum KIRDecl: Hashable {
  case binding(Identifier, KIRExpr)
}

public struct KIRExprBlock: Hashable {
  public let decls: [KIRDecl]
  public let expr: KIRExpr
}

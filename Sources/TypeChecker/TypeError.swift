//
//  Created by Max Desiatov on 28/05/2019.
//

import Syntax

enum TypeError: Error, Equatable {
  case ambiguous(Identifier)
  case invalidFunctionMember(MemberAccess.Member)
  case invalidStaticMember(MemberAccess.Member)
  case infiniteType(TypeVariable, Type)
  case noOverloadFound(Identifier, Type)
  case tupleIndexOutOfRange([Type], addressed: Int)
  case unificationFailure(Type, Type)
  case unknownType(Identifier)
  case unknownMember(Identifier, Identifier)
  case unknownTupleMember(MemberAccess.Member)
  case unbound(Identifier)
  case tupleUnificationFailure(Identifier, Identifier)
  case noExpressionsInBlock(SourceRange<Empty>)
  case topLevelAnnotationMissing(Identifier)
  case typeDeclAlreadyExists(Identifier)
  case funcDeclAlreadyExists(Identifier)
  case bindingDeclAlreadyExists(Identifier)
  case multipleInteropModifiers
  case funcDeclBodyMissing(Identifier)
  case typeMismatch(Identifier, expected: Type, actual: Type)
  case exprIsNotType(SourceRange<Empty>)
}

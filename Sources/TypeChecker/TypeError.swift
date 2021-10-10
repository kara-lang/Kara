//
//  Created by Max Desiatov on 28/05/2019.
//

import Syntax

enum TypeError: Error, Equatable {
  case ambiguous(Identifier)
  case arrowMember(Identifier)
  case infiniteType(TypeVariable, Type)
  case noOverloadFound(Identifier, Type)
  case tupleIndexOutOfRange(total: Int, addressed: Int)
  case unificationFailure(Type, Type)
  case unknownType(TypeIdentifier)
  case unknownMember(TypeIdentifier, Identifier)
  case unknownTupleMember(Identifier)
  case unbound(Identifier)
  case tupleUnificationFailure(Identifier, Identifier)
  case noExpressionsInBlock(SourceRange<()>)
  case topLevelAnnotationMissing(Identifier)
  case typeDeclAlreadyExists(TypeIdentifier)
  case funcDeclAlreadyExists(Identifier)
  case bindingDeclAlreadyExists(Identifier)
  case multipleInteropModifiers
  case funcDeclBodyMissing(Identifier)
  case returnTypeMismatch(expected: Type, actual: Type)
}

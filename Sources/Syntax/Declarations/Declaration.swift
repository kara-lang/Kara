//
//  Created by Max Desiatov on 04/09/2021.
//

import Parsing

public enum Declaration<A: Annotation> {
  case binding(BindingDecl<A>)
  case function(FuncDecl<A>)
  case `struct`(StructDecl<A>)
  case `enum`(EnumDecl<A>)
  case trait(TraitDecl<A>)
}

let declarationParser: AnyParser<ParsingState, SyntaxNode<Declaration<EmptyAnnotation>>> =
  funcDeclParser.map { $0.map(Declaration.function) }
    .orElse(structParser.map { $0.map(Declaration.struct) })
    .orElse(enumParser.map { $0.map(Declaration.enum) })
    .orElse(traitParser.map { $0.map(Declaration.trait) })
    .orElse(bindingParser.map { $0.map(Declaration<EmptyAnnotation>.binding) })
    // Required to give `declarationParser` an explicit type signature, otherwise this won't compile due to mutual
    // recursion with subexpression parsers.
    .eraseToAnyParser()

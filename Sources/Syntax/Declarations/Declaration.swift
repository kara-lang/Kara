//
//  Created by Max Desiatov on 04/09/2021.
//

import Parsing

public enum Declaration {
  case binding(BindingDecl)
  case function(FuncDecl)
  case `struct`(StructDecl)
  case trait(TraitDecl)
}

let declarationParser: AnyParser<ParsingState, SyntaxNode<Declaration>> =
  funcDeclParser.map { $0.map(Declaration.function) }
    .orElse(structParser.map { $0.map(Declaration.struct) })
    .orElse(traitParser.map { $0.map(Declaration.trait) })
    .orElse(bindingParser.map { $0.map(Declaration.binding) })
    // Required to give `declarationParser` an explicit type signature, otherwise this won't compile due to mutual
    // recursion with subexpression parsers.
    .eraseToAnyParser()

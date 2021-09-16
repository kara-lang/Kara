//
//  Created by Max Desiatov on 16/09/2021.
//

import Codegen
import Syntax

typealias JSCodegen<T> = CompilerPass<T, String>

let jsModuleCodegen = JSCodegen<ModuleFile> { _ in
  "blah"
}

let jsFunctionCodegen = JSCodegen<FunctionDecl> {
  """
  const \($0.identifier.value) =
    (\($0.parameters.elementsContent.map(\.internalName))) => \(jsExprCodegen($0.body?.content.content ?? .unit));
  """
}

let jsExprCodegen = JSCodegen<Expr> { _ in
  "blah"
//    switch $0 {
//    case let .literal(.bool(bool)):
//        return bool.description
//    case let .literal(.int32(int)):
//    }
}

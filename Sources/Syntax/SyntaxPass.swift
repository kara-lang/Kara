//
//  Created by Max Desiatov on 02/10/2021.
//

import Basic

public let syntaxPass = CompilerPass { (source: String) -> ModuleFile<EmptyAnnotation> in
  // FIXME: error handling, assert is fully parsed
  moduleFileParser.parse(.init(stringLiteral: source)).output!
}

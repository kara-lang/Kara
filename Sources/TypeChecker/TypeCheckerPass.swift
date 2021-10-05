//
//  Created by Max Desiatov on 03/10/2021.
//

import Basic
import Syntax

func typeCheck(module: ModuleFile) throws -> ModuleFile {
  module
}

public let typeCheckerPass = CompilerPass { (module: ModuleFile) -> ModuleFile in
  // FIXME: detailed diagnostics
  // swiftlint:disable:next force_try
  try! typeCheck(module: module)
}

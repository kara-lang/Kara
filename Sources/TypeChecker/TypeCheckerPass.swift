//
//  Created by Max Desiatov on 03/10/2021.
//

import Basic
import Syntax

extension ModuleFile {
  func typeCheck() throws {
    _ = try environment
  }
}

public let typeCheckerPass = CompilerPass { (module: ModuleFile) -> ModuleFile in
  // FIXME: detailed diagnostics
  // swiftlint:disable:next force_try
  try! module.typeCheck()
  return module
}

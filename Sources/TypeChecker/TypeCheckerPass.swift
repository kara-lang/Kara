//
//  Created by Max Desiatov on 03/10/2021.
//

import Basic
import Syntax

public let typeCheckerPass = CompilerPass { (module: ModuleFile) -> ModuleFile in
  // FIXME: detailed diagnostics
  module
}

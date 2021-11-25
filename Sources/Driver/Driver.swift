//
//  Created by Max Desiatov on 24/11/2021.
//

import Basic
import JSCodegen
import Syntax
import TypeChecker

public let driverPass = syntaxPass | typeCheckerPass | jsModuleFileCodegen

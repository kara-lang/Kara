//
//  Created by Max Desiatov on 08/10/2021.
//

import Syntax

/** Environment that maps a given `Identifier` to its `Scheme` type signature. */
typealias Environment = [Identifier: Scheme]
typealias Members = [TypeIdentifier: Environment]

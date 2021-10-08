//
//  Created by Max Desiatov on 08/10/2021.
//

import Syntax

/** Environment of possible overloads for `Identifier`. There's an assumption
 that `[Scheme]` array can't be empty, since an empty array of overloads is
 meaningless. If no overloads are available for `Identifier`, it shouldn't be
 in the `Environoment` dictionary as a key in the first place.
 */
typealias Environment = [Identifier: [Scheme]]
typealias Members = [TypeIdentifier: Environment]

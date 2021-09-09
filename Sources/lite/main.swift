//
//  Created by Max Desiatov on 08/09/2021.
//

import Foundation
import LiteSupport

let allPassed = try runLite(
  substitutions: [],
  pathExtensions: ["kara"],
  testDirPath: nil,
  testLinePrefix: "//",
  parallelismLevel: .automatic
)

exit(allPassed ? EXIT_SUCCESS : EXIT_FAILURE)

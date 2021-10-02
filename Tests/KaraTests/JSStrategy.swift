//
//  Created by Max Desiatov on 01/10/2021.
//

import SnapshotTesting

public extension Snapshotting where Value == String, Format == String {
  static let js = Snapshotting(pathExtension: "jss", diffing: .lines)
}

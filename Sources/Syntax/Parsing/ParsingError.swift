//
//  Created by Max Desiatov on 19/08/2021.
//

public enum ParsingError: Error {
  case unknown(Range<String.Index>)
}

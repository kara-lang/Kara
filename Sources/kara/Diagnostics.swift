//
//  Created by Max Desiatov on 10/08/2021.
//

import Parsing

struct SourceLocation<Element> {
  let start: String.Index
  let end: String.Index

  let element: Element
}

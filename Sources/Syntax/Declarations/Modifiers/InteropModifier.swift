//
//  Created by Max Desiatov on 21/09/2021.
//

struct InteropModifier {
  enum Language: String {
    case js = "JS"
    case c = "C"
    case swift = "Swift"
  }

  let language: Language
  let externalName: String
}

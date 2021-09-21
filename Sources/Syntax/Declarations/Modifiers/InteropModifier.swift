//
//  Created by Max Desiatov on 21/09/2021.
//

struct InteropModifier {
  enum Language {
    case js
    case c
    case swift
  }

  let language: Language
  let externalName: String
}

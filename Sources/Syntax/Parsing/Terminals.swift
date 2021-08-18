//
//  Created by Max Desiatov on 19/08/2021.
//

import Parsing

typealias UTF8SubSequence = String.UTF8View.SubSequence
typealias UTF8Terminal = StartsWith<UTF8SubSequence>

let newlineAndWhitespace = [UInt8(ascii: " "), UInt8(ascii: "\n"), UInt8(ascii: "\r")]

let whitespaceParser = Whitespace<UTF8SubSequence>()
let requiredWhitespaceParser = OneOfMany(
  newlineAndWhitespace
    .compactMap { String(bytes: [$0], encoding: .utf8) }
    .map { StartsWith<UTF8SubSequence>($0.utf8) }
)

let openBraceParser = UTF8Terminal("{".utf8)
let closeBraceParser = UTF8Terminal("}".utf8)

let openParenParser = UTF8Terminal("(".utf8)
let closeParenParser = UTF8Terminal(")".utf8)

let commaParser = UTF8Terminal(",".utf8)

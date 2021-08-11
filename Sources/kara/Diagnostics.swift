//
//  Created by Max Desiatov on 10/08/2021.
//

import Parsing

extension Parsers {
    struct ConsumedCount<P: Parser>: Parser where P.Input: Collection {
        init(parser: P) {
            self.parser = parser
        }

        let parser: P

        func parse(_ input: inout P.Input) -> (P.Output, Int)? {
            let original = input
            let result = parser.parse(&input)

            return result.map { ($0, original.count - input.count) }
        }
    }
}

extension Parser where Input: Collection {
    func consumedCount() -> Parsers.ConsumedCount<Self> {
        .init(parser: self)
    }
}

//
//  Created by Max Desiatov on 16/08/2021.
//

public struct Lambda: Equatable {
  init(identifiers: [Identifier], body: Expr) {
    parameters = identifiers.map { Parameter(identifier: $0, typeAnnotation: nil) }
    self.body = body
  }

  public struct Parameter: Equatable {
    public let identifier: Identifier
    let typeAnnotation: Type?
  }

  public let parameters: [Parameter]
  public let body: Expr
}

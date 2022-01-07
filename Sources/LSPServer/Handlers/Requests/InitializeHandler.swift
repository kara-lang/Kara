//
//  Created by Max Desiatov on 24/11/2021.
//

import LanguageServerProtocol

extension InitializeRequest: RequestHandler {
  static var witness: RequestHandlingWitness<Self> {
    .init(
      handle: { request, server in
        await server.setShouldSendDiagnostics(
          request.capabilities.textDocument?.publishDiagnostics?.relatedInformation ?? false
        )

        return .success(
          .init(
            capabilities:
            .init(
              textDocumentSync: .init(),
              hoverProvider: false,
              completionProvider: nil,
              signatureHelpProvider: nil,
              definitionProvider: nil,
              typeDefinitionProvider: nil,
              implementationProvider: nil,
              referencesProvider: nil,
              documentHighlightProvider: nil,
              documentSymbolProvider: nil,
              workspaceSymbolProvider: nil,
              codeActionProvider: nil,
              codeLensProvider: nil,
              documentFormattingProvider: nil,
              documentRangeFormattingProvider: nil,
              documentOnTypeFormattingProvider: nil,
              renameProvider: nil,
              documentLinkProvider: nil,
              colorProvider: nil,
              foldingRangeProvider: nil,
              declarationProvider: nil,
              executeCommandProvider: nil,
              workspace: nil,
              callHierarchyProvider: nil,
              semanticTokensProvider: nil,
              experimental: nil
            )
          )
        )
      }
    )
  }
}

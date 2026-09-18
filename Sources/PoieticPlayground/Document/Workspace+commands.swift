//
//  Workspace+commands.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 14/09/2026.
//

extension Workspace {
    /// Execute given command in the context of the document. Re-throws command error.
    ///
    /// - SeeAlso: ``executeWithReporting(_:document:canvas:)``
    ///
    @MainActor
    func execute(_ command: Command, document: Document, canvas: DiagramCanvas? = nil) throws (CommandError) {
        let context = CommandContext(document: document, canvas: canvas)
        try command.run(context)
    }

    /// Executes given command in the context of the document. Presents alerts on command failure.
    ///
    /// - SeeAlso: ``execute(_:document:canvas:)``
    /// 
    @MainActor
    func executeWithReporting(_ command: Command, document: Document, canvas: DiagramCanvas? = nil) {
        let context = CommandContext(document: document, canvas: canvas)

        do {
            environment?.log("Running command '\(command.name)'")
            try command.run(context)
        }
        catch {
            environment?.logError("Command '\(command.name)' failed: \(error.message)")
            if let underlyingError = error.underlyingError {
                environment?.logError("Underlying error: \(String(describing: underlyingError))")
            }
            let message: String
            
            let title: String
            switch error.kind {
            case .user:
                title = "Error"
                message = error.message
            case .internal:
                title = "Internal Error"
                message = "Please contact developers. Underlying error: " + error.message
                
            }
            
            environment?.report(title: title, message: error.message, style: .error)
        }
    }

}

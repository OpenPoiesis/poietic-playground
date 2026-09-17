//
//  Workspace+commands.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 14/09/2026.
//

extension Workspace {
    @MainActor
    func execute(_ command: Command, document: Document, canvas: DiagramCanvas? = nil) {
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
            
            environment?.presentMessage(title: title, message: error.message, style: .error)
        }
    }
}

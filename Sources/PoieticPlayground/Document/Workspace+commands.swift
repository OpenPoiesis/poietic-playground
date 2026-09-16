//
//  Workspace+commands.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 14/09/2026.
//

// FIXME: Use app logging
extension Workspace {
    func log(_ message: String) {
        print("INFO: ", message)
    }
    func logError(_ message: String) {
        print("ERROR: ", message)
    }
    func queueAlert(title: String, message: String) {
        app?.queueAlert(title: title, message: message)
    }
}


extension Workspace {
    @MainActor
    func runCommand(_ command: Command, document: Document, canvas: DiagramCanvas?) {
        let context = CommandContext(workspace: self,
                                     document: document,
                                     canvas: canvas)
        do {
            self.log("Running command '\(command.name)'")
            try command.run(context)
        }
        catch {
            self.logError("Command '\(command.name)' failed: \(error.message)")
            if let underlyingError = error.underlyingError {
                self.logError("Underlying error: \(String(describing: underlyingError))")
            }
            let title: String
            switch error.severity {
            case .fatal: title = "Fatal Error"
            case .error: title = "Error"
            }
            
            self.queueAlert(title: title, message: error.message)
        }
    }
}

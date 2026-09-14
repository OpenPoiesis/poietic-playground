//
//  Workspace+commands.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 14/09/2026.
//

extension Workspace {
    func queueCommand(_ command: any WorkspaceCommand) {
        let item = QueuedCommand(command: command,
                                 document: currentDocument,
                                 canvas: canvas)
        self.commandQueue.append(item)
    }
    
    @MainActor
    func runCommand(_ command: WorkspaceCommand, document: Document, canvas: DiagramCanvas?) {
        let context = WorkspaceCommandContext(workspace: self,
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

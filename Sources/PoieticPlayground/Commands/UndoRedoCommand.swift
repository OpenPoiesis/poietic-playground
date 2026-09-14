//
//  UndoRedoCommand.swift
//  poietic-tool
//
//  Created by Stefan Urbanek on 09/02/2026.
//

import PoieticCore
import PoieticFlows
import Foundation

struct UndoCommand: WorkspaceCommand {
    var name: String { "undo" }
    
    @MainActor
    func run(_ context: WorkspaceCommandContext) throws (CommandError) {
        context.document?.hadTransactionSinceSave = true
        context.design?.undo() // The plane change will be detected and handled through Document
    }
}

struct RedoCommand: WorkspaceCommand {
    var name: String { "redo" }
    
    @MainActor
    func run(_ context: WorkspaceCommandContext) throws (CommandError) {
        context.document?.hadTransactionSinceSave = true
        context.design?.redo() // The plane change will be detected and handled through Document
    }
}

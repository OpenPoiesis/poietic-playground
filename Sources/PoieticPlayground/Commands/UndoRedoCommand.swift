//
//  UndoRedoCommand.swift
//  poietic-tool
//
//  Created by Stefan Urbanek on 09/02/2026.
//

import PoieticCore
import PoieticFlows
import Foundation

struct UndoCommand: Command {
    var name: String { "undo" }

    // TODO: Add result detail, if undo happened
    @MainActor
    func run(_ context: CommandContext) throws (CommandError) {
        context.document.hadTransactionSinceSave = true
        context.design.undo() // The plane change will be detected and handled through Document
    }
}

struct RedoCommand: Command {
    var name: String { "redo" }
    // TODO: Add result detail, if redo happened
    @MainActor
    func run(_ context: CommandContext) throws (CommandError) {
        context.document.hadTransactionSinceSave = true
        context.design.redo() // The plane change will be detected and handled through Document
    }
}

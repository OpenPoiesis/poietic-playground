//
//  EditCommands.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 13/02/2026.
//

import PoieticCore
import PoieticFlows
import Foundation

struct DeleteObjectsCommand: Command {
    let ids: [ObjectID]
    var name: String { "delete" }
    
    init(_ ids: [ObjectID]) {
        self.ids = ids
    }
    
    @MainActor
    func run(_ context: CommandContext) throws (CommandError) {
        let trans = context.document.createOrReuseTransaction()
        for objectID in ids {
            guard trans.contains(objectID) else { continue }
            trans.removeCascading(objectID)
        }
    }
}

struct InsertObjectsCommand: Command {
    var name: String { "paste" }
    /// Raw design to be pasted.
    ///
    /// The raw design must satisfy one of the following:
    /// - Must contain only single plane.
    /// - OR Must contain only snapshots (no plane)
    /// - OR Must contain valid current plane.
    ///
    let rawDesign: RawDesign
    let strategy: DesignLoader.IdentityStrategy
    
    init(rawDesign: RawDesign, strategy: DesignLoader.IdentityStrategy = .preserveOrCreate) {
        self.rawDesign = rawDesign
        self.strategy = strategy
    }
    
    @MainActor
    func run(_ context: CommandContext) throws (CommandError) {
        let trans = context.document.createOrReuseTransaction()

        let loader = DesignLoader(metamodel: trans.design.metamodel)
        let ids: [PoieticCore.ObjectID]

        do {
            ids = try loader.load(rawDesign,
                                  into: trans,
                                  identityStrategy: strategy)
        }
        catch {
            context.document.discardTransaction()
            throw CommandError("Failed to paste content", underlyingError: error)
        }

        // TODO: Decouple selection from insert (we need flag "recently inserted/updated/flagged" or something like that)
        context.document.changeSelection(.replaceAll(ids))
    }
}




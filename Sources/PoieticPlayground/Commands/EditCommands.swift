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
        guard let document = context.document else { return }
        let trans = document.createOrReuseTransaction()
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
        guard let document = context.document else { return }

        let trans = document.createOrReuseTransaction()

        let loader = DesignLoader(metamodel: trans.design.metamodel)
        let ids: [PoieticCore.ObjectID]

        do {
            ids = try loader.load(rawDesign,
                                  into: trans,
                                  identityStrategy: strategy)
        }
        catch {
            document.discardTransaction()
            throw CommandError("Failed to paste content", underlyingError: error)
        }

        document.changeSelection(.replaceAll(ids))
    }
}




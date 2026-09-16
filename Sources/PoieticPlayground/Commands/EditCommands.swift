//
//  EditCommands.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 13/02/2026.
//

import PoieticCore
import PoieticFlows
import Foundation

extension Document {
    static func copySelectionAsText(ids: [ObjectID], plane: DesignPlane) throws (CommandError) -> String {
        let design = plane.design
        let ids = plane.contained(ids)
        
        let extractor = DesignExtractor()
        let extract = extractor.extractPruning(objects: ids, plane: plane)
        let rawDesign = RawDesign(metamodelName: design.metamodel.name,
                                  metamodelVersion: design.metamodel.version,
                                  snapshots: extract)
        
        let writer = JSONDesignWriter()
        guard let text: String = writer.write(rawDesign) else {
            throw CommandError("Unable to get textual representation for pasteboard", severity: .fatal)
        }
        return text
    }
}

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

struct CopyToPasteboardCommand: Command {
    let ids: [ObjectID]
    var name: String { "copy" }
    init(_ ids: [ObjectID]) {
        self.ids = ids
    }
    @MainActor
    func run(_ context: CommandContext) throws (CommandError) {
        guard let plane = context.world?.plane else { return }
        let text = try Document.copySelectionAsText(ids: ids, plane: plane)
        try Application.setPasteboardText(text)
        
    }
    
}

struct CutToPasteboardCommand: Command {
    let ids: [ObjectID]
    var name: String { "cut" }

    init(_ ids: [ObjectID]) {
        self.ids = ids
    }
    
    @MainActor
    func run(_ context: CommandContext) throws (CommandError) {
        guard let plane = context.world?.plane,
              let document = context.document
        else { return }
        
        let text = try Document.copySelectionAsText(ids: ids, plane: plane)
        try Application.setPasteboardText(text)

        let trans = document.createOrReuseTransaction()
        for objectID in ids {
            guard trans.contains(objectID) else { continue }
            trans.removeCascading(objectID)
        }
    }
}

struct PasteFromPasteboardCommand: Command {
    var name: String { "paste" }

    init() { /* Nothing */ }
    
    @MainActor
    func run(_ context: CommandContext) throws (CommandError) {
        guard let text = try Application.getPasteboardText(),
              let document = context.document
        else { return }

        let trans = document.createOrReuseTransaction()

        guard let data = text.data(using: .utf8) else {
            throw CommandError("Can not get data from text")
        }

        let reader = JSONDesignReader()
        let rawDesign: RawDesign
        do {
            rawDesign = try reader.read(data: data)
        }
        catch {
            throw CommandError("Unable to process pasteboard content", underlyingError: error)
        }

        let loader = DesignLoader(metamodel: trans.design.metamodel)
        let ids: [PoieticCore.ObjectID]

        do {
            // TODO: Make the strategy configurable
            ids = try loader.load(rawDesign,
                                  into: trans,
                                  identityStrategy: .preserveOrCreate)
        }
        catch {
            document.discardTransaction()
            throw CommandError("Failed to paste content", underlyingError: error)
        }

        document.changeSelection(.replaceAll(ids))
    }

}




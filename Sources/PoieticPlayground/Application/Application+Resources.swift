//
//  App+resources.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 01/02/2026.
//

import PoieticCore
import PoieticFlows
import Diagramming
import Foundation

/// Makeshift notation catalog.
///
class NotationCatalog {
    struct Entry {
        let name: String
        let path: String
    }
    var entries: [Entry]
    
    init(_ entries: [Entry]) {
        self.entries = entries
    }

    func path(forNotationNamed name: String) -> String? {
        guard let entry = entries.first(where: { $0.name == name })
        else { return nil }
        return entry.path
    }
}

extension Application {
    func loadResources() {
        let notationURL = resourceManager.resourceURL(Self.DefaultStockFlowPictogramsPath)
        self.loadNotation(url: notationURL)
    }

    func loadNotation(url: URL) {
        // Notations are created from pictograms which are created by `pictogram` CLI tool of
        // Diagramming (poietic-diagram) package. See the Diagramming package documentation.
        //
        let data: Data
        do {
            data = try Data(contentsOf: url)
        }
        catch {
            logError("Unable to load notation from: \(url)")
            return
        }
        
        let decoder = JSONDecoder()
        let collection: PictogramCollection
        
        do {
            collection = try decoder.decode(PictogramCollection.self, from: data)
        }
        catch {
            logError("Unable to load pictograms from: \(url). Reason: \(error)")
            collection = PictogramCollection()
        }
        if collection.pictograms.isEmpty {
            logError("No pictograms found (empty collection)")
        }
        
        let scaled = collection.pictograms.map { $0.scaled(Self.PictogramAdjustmentScale) }
        
        let notation = Diagramming.Notation(
            pictograms: scaled,
            defaultPictogramName: "Unknown",
            connectorGlyphs: DefaultStockFlowConnectorGlyphs,
            defaultConnectorGlyphName: "default"
        )
        self.log("Notation loaded. \(notation.pictograms.count) pictograms, \(notation.connectorGlyphs.count) connector glyphs.")
        self.notation = notation
        
        // TODO: Should belong to Document.
        self.workspace?.currentDocument?.setNotation(notation)
    }
    
    func setNotation(named name: String) {
        // TODO: Later, make this per-document setting.
        guard let path = Self.KnownNotations.path(forNotationNamed: name)
        else {
            self.logError("Unknown notation \(name). Notation change ignored.")
            return
        }
        let url = resourceManager.resourceURL(path)
        loadNotation(url: url)
        self.notationName = name
        
    }
}

//
//  Workspace+Document.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 14/09/2026.
//

import PoieticCore
import PoieticFlows
import Foundation


extension Workspace {
    func newDesign() {
        let design = Design(metamodel: StockFlowDomain.StockFlowMetamodel)
        // Create a new empty plane, so we can undo first action (can't undo to no-plane)
        let plane = design.createPlane()
        try! design.accept(plane) // We can force, because empty plane must be always valid.
        let document = Document(design: design, url: nil, notation: notation)
        self.replaceDocument(document)
    }
    
    func openDesign(url: URL) throws (DesignStoreError) {
        let store = DesignStore(url: url)
        let design = try store.load(metamodel: StockFlowDomain.StockFlowMetamodel)
        let document = Document(design: design, url: url, notation: notation)
        self.replaceDocument(document)
    }
}

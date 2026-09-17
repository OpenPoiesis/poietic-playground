//
//  Document+Commands.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 25/03/2026.
//

import PoieticFlows
import PoieticCore
import Foundation

public enum AutoCorrectParametersSchedule: ScheduleLabel {}

extension Document {
    func autoConnectParameters() {
        
        // We can just run it, as this method is called when the world is populated. If it is not,
        // we are fine too - just do nothing. This is an optional utility, not to be put in a
        // critical path.
        // It is a non-throwing system, we run it gracefully
        try? ParameterConnectionProposalSystem.update(self.world)

        guard let proposal: ParameterProposal = world.singleton(),
              !proposal.isEmpty
        else {
            self.queueAlert(title: "Auto-Connect Parameters",
                            message: "Nothing automatically proposed for parameter connections")
            return
        }
        
        let trans = self.createOrReuseTransaction()

        for id in proposal.toRemove {
            trans.removeCascading(id)
        }
        for edgeProposal in proposal.toAdd {
            trans.createEdge(StockFlowDomain.Types.Parameter, origin: edgeProposal.origin, target: edgeProposal.target)
        }

        self.queueAlert(title: "Auto-Connect Parameters",
                        message: "Removed \(proposal.toRemove.count), created \(proposal.toAdd.count) connections.")

    }
    
    func save(to url: URL) throws (DesignStoreError) {
        let store = DesignStore(url: url)
        try store.save(design: design)
        self.designURL = url
        self.hadTransactionSinceSave = false
    }
    
    /// Serialise objects with given IDs as a text.
    ///
    /// The method first extracts objects by pruning loose ends (for example requested edges where
    /// one or both endpoints are not in the list).
    ///
    func serialiseForTextExport(ids: [ObjectID]) -> String? {
        guard let plane = design.currentPlane else { return nil }
        let ids = plane.contained(ids)
        
        let extractor = DesignExtractor()
        let extract = extractor.extractPruning(objects: ids, plane: plane)
        let rawDesign = RawDesign(metamodelName: design.metamodel.name,
                                  metamodelVersion: design.metamodel.version,
                                  snapshots: extract)
        
        let writer = JSONDesignWriter()
        return writer.write(rawDesign)
    }


}

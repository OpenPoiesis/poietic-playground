//
//  WorkspaceServices.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 18/09/2026.
//

import PoieticCore
import Diagramming

@MainActor
protocol WorkspaceServices: AnyObject {
    func switchTool(_ tool: CanvasToolType)
    func openIssues(for objectID: ObjectID?)
    func centerView(at position: Vector2D, zoom: Double?)
    func locateInView(object objectID: ObjectID, zoom: Double?)
}

extension Workspace: WorkspaceServices {
    func openIssues(for objectID: ObjectID?) {
        self.issuesPanel.isVisible = true
        self.issuesPanel.setSelectedObject(objectID)
    }
    
    func centerView(at position: Vector2D, zoom: Double?) {
        canvas.centerView(at: position, zoom: zoom)
    }
    
    func locateInView(object objectID: ObjectID, zoom: Double?) {
        guard let entity = currentDocument?.world.entity(objectID),
              let block: DiagramBlock = entity.component()
        else { return }
        // TODO: Use some more clever method
        canvas.centerView(at: block.position, zoom: zoom)
    }

    func switchTool(_ tool: CanvasToolType) {
        toolManager.select(tool)
    }
}

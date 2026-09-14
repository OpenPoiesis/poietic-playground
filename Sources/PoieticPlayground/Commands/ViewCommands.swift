//
//  ViewCommands.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 14/09/2026.
//

import PoieticCore
import Diagramming

struct SwitchToolCommand: WorkspaceCommand {
    var name: String { "switch-tool" } // TODO: Use CanvasTool.Type

    let toolType: CanvasToolType

    init(_ toolType: CanvasToolType) {
        self.toolType = toolType
    }

    @MainActor
    func run(_ context: WorkspaceCommandContext) throws (CommandError) {
        context.workspace?.toolBar.setTool(toolType)
    }
}

struct OpenIssuesCommand: WorkspaceCommand {
    var name: String { "open-issues" }

    /// Object to open issues for. If nil - open for all.
    let objectID: ObjectID?
    
    init(_ objectID: ObjectID? = nil) {
        self.objectID = objectID
    }
    
    @MainActor
    func run(_ context: WorkspaceCommandContext) throws (CommandError) {
        context.workspace?.issuesPanel.isVisible = true
    }
}

struct CenterCanvasOnObjectCommand: WorkspaceCommand {
    // TODO: Seems to be centring incorrectly, needs verification
    // TODO: Make it work with other objects, Works only with blocks for now
    var name: String { "center-canvas-on-object" }

    let objectID: ObjectID
    let zoomLevel: Double?
    
    init(_ objectID: ObjectID, zoomLevel: Double? = nil) {
        self.objectID = objectID
        self.zoomLevel = zoomLevel
    }
    
    @MainActor
    func run(_ context: WorkspaceCommandContext) throws (CommandError) {
        print("CENTER ON: \(objectID), zoom: \(zoomLevel)")
        guard let entity = context.world?.entity(objectID),
              let block: DiagramBlock = entity.component()
        else {return }
        context.canvas?.centerView(at: block.position)
    }
}

struct ResetZoomCommand: WorkspaceCommand {
    var name: String { "reset-zoom" }
    
    @MainActor
    func run(_ context: WorkspaceCommandContext) throws (CommandError) {
        guard let canvas = context.canvas else { return }
        let worldSize: Vector2D = canvas.screenToWorld(canvas.canvasSize)
        let center = canvas.viewOffset + (worldSize / 2)
        canvas.centerView(at: center, zoom: 1.0)
    }
}


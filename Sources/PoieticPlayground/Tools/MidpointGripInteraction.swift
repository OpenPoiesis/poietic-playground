//
//  MidpointGripInteraction.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 23/09/2026.
//

import PoieticCore
import Diagramming

// TODO: Break into SelectionInteraction and ObjectMoveInteraction

@MainActor
class MidpointGripInteraction: ToolInteraction {
    let context: ToolContext
    var document: Document { context.document }
    var canvas: DiagramCanvas { context.canvas }
    
    var world: World { document.world }
    
    let gripID: RuntimeID
    
    enum State: Equatable {
        case idle
        case engaged
        case dragging
    }
    
    var state: State = .idle
    var dragStartScreenPos: Vector2D = .zero
    
    init(context: ToolContext, grip gripID: RuntimeID) {
        self.context = context
        self.gripID = gripID
        self.state = .idle
    }
    
    func begin() {
        state = .idle
        dragStartScreenPos = .zero
    }
    
    func end() {
        state = .idle
        dragStartScreenPos = .zero
    }
    
    func handleEvent(_ event: ToolEvent) -> EventDisposition {
        switch event.type {
        case .pointerDown: return self.pointerDown(event)
        case .dragStart: return self.dragStart(event)
        case .dragMove: return self.dragMove(event)
        case .dragEnd: return self.dragEnd(event)
        case .dragCancel: return self.dragCancel(event)
        default: return .ignored
        }
    }
    
    // MARK: - Events
    
    func pointerDown(_ event: ToolEvent) -> EventDisposition {
        guard event.triggerButton == .left
        else { return .ignored }
        dragStartScreenPos = event.screenPos
        
        state = .engaged
        
        return .engaged
    }

    func dragStart(_ event: ToolEvent) -> EventDisposition {
        switch state {
        case .idle:
            return .ignored
        case .engaged, .dragging:
            document.beginInteractivePreview()
            dragGrip(gripID, screenDelta: event.delta)
            state = .dragging
            return .engaged
        }
    }

    func dragMove(_ event: ToolEvent) -> EventDisposition {
        switch state {
        case .idle:
            return .ignored

        case .engaged, .dragging:
            dragGrip(gripID, screenDelta: event.delta)
            state = .dragging
            return .engaged
        }
    }

    func dragEnd(_ event: ToolEvent) -> EventDisposition {
        defer {
            document.endInteractivePreview()
            state = .idle
        }
        // TODO: Mouse cursors
        let screenDelta = event.screenPos - self.dragStartScreenPos
        let worldDelta = Vector2D(screenDelta) / canvas.zoomLevel
        
        switch state {
        case .idle, .engaged:
            return .ignored

        case .dragging:
            guard let grip = document.world.entity(gripID) else {
                return .ignored
            }
            let worldPosition: Vector2D = canvas.screenToWorld(event.screenPos)
            finalizeGripMove(grip, finalPosition: worldPosition, totalDelta: worldDelta)

            state = .idle
            return .handled
        }
    }
    
    func dragCancel(_ event: ToolEvent) -> EventDisposition {
        document.endInteractivePreview()
        
        if state == .idle { return .ignored }
        else { return .handled }
    }
    
    // MARK: - Grip Drag
    
    func dragGrip(_ gripRuntimeID: RuntimeID, screenDelta: Vector2D) {
        guard let grip = document.world.entity(gripRuntimeID),
              var component: Grip = grip.component()
        else { return }
        
        let worldDelta = screenDelta / canvas.zoomLevel
        component.worldPosition += worldDelta
        grip.setComponent(component)
        grip.setComponent(PositionComponent(position: canvas.worldToScene(component.worldPosition)))

        switch component.key {
        case .connectorMidpoint(let index):
            guard let target: RuntimeEntity = grip.target(GripOf.self) else { break }
            dragMidpointGrip(target, index: index, currentPosition: component.worldPosition, currentDelta: worldDelta)
            target.setComponent(DirtyContent.geometry)
        }
        
        document.queueInteractivePreviewUpdate()
    }
    
    /// Reflect handle position to connector preview.
    ///
    func dragMidpointGrip(_ target: RuntimeEntity, index: Int, currentPosition: Vector2D, currentDelta: Vector2D) {
        var midpoints: [Vector2D]
        
        if let preview: PreviewMidpoints = target.component() {
            if preview.midpoints.isEmpty {
                midpoints = [currentPosition]
            }
            else {
                midpoints = preview.midpoints

                if index >= 0 && index < preview.midpoints.count {
                    midpoints[index] = currentPosition
                }
            }
        }
        else {
            midpoints = [currentPosition]
        }
        
        let newPreview = PreviewMidpoints(midpoints: midpoints)
        target.setComponent(newPreview)
    }

    /// Parameters:
    ///     - handleRuntimeID:
    
    func finalizeGripMove(_ grip: RuntimeEntity, finalPosition: Vector2D, totalDelta: Vector2D) {
        guard let component: Grip = grip.component()
        else { return }

        switch component.key {
        case .connectorMidpoint(let index):
            guard let target: RuntimeEntity = grip.target(GripOf.self) else { break }
            finalizeMidpointMove(target: target, index: index, finalPosition: finalPosition)
        }
        document.queueInteractivePreviewUpdate()
    }

    func finalizeMidpointMove(target: RuntimeEntity, index: Int, finalPosition: Vector2D) {
        guard let objectID = target.objectID
        else { return }
        
        let trans = document.createOrReuseTransaction()
        guard trans.contains(objectID) else { return }
        
        let object = trans.mutate(objectID)
        guard object.type.hasTrait(DiagramDomain.Traits.DiagramConnector) else { return }
        
        if var midpoints: [Point] = object["midpoints"] {
            guard index < midpoints.count else { return }
            midpoints[index] = finalPosition
            object["midpoints"] = Variant(midpoints)
        }
        else {
            object["midpoints"] = Variant([finalPosition])
        }

    }
}

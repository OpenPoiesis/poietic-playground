//
//  SelectionInteraction.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 21/09/2026.
//

import PoieticCore
import Diagramming

// TODO: Break into SelectionInteraction and ObjectMoveInteraction

@MainActor
class SelectionInteraction: ToolInteraction {
    let context: ToolContext
    var document: Document { context.document }
    var canvas: DiagramCanvas { context.canvas }
    
    var world: World { document.world }
    
    enum State: Equatable {
        /// Nothing hit, initial state
        case idle
        /// Direct hit of a single object, typically a block or a connector.
        case objectHit
        /// Object selection initiated.
        case objectSelect
        /// Dragging selection around.
        case objectMove
        /// Object part was hit, such as label or issue indicator.
        case objectPartHit(RuntimeID, CanvasObjectHit.ObjectPart)
    }
    
    var state: State = .idle
    var dragStartScreenPos: Vector2D = .zero
    
    init(context: ToolContext) {
        self.context = context
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
        
        // TODO: Close inline popup
        let selection = document.selection
        guard let target = canvas.hitObject(screenPosition: event.screenPos) else {
            document.changeSelection(.removeAll)
            state = .objectSelect
            return .handled
        }

        switch target.part {
        case .body:
            // TODO: Defer opening of context menu on inputEnded or move context menu out of the tool
            guard let objectID = world.entity(target.designObject)?.objectID
            else { return .handled } // Not a design object
            
            if event.modifiers.contains(.shift) {
                document.changeSelection(.toggle(objectID))
            }
            else {
                if selection.contains(objectID) {
                    // TODO: Implement context menu, at screenPosition
                    print("TODO: open popup for \(selection.ids) not implemented")
                }
                else {
                    document.changeSelection(.replaceAllWithOne(objectID))
                }
            }
            state = .objectHit

        case .issueIndicator:
            state = .idle
            guard let objectID = world.entity(target.designObject)?.objectID else { break }
            context.openIssues(for: objectID)

        case .primaryLabel, .secondaryLabel:
            state = .objectPartHit(target.designObject, target.part)
        }
        
        return .handled
    }
    func dragStart(_ event: ToolEvent) -> EventDisposition {
//        TODO: popupManager?.closeInlinePopup()
        switch state {
        case .idle, .objectSelect:
            return .ignored
        case .objectHit, .objectPartHit, .objectMove:
            document.beginInteractivePreview()
            previewSelectionMove(screenDelta: event.delta)
            state = .objectMove
            return .engaged
        }
    }

    func dragMove(_ event: ToolEvent) -> EventDisposition {

//        TODO: popupManager?.closeInlinePopup()
        switch state {
        case .idle, .objectSelect:
            return .ignored

        case .objectHit, .objectMove, .objectPartHit:
            previewSelectionMove(screenDelta: event.delta)
            state = .objectMove
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
        case .objectMove:
            finalizeSelectionMove(document.selection, by: worldDelta)
            return .handled

        case .idle, .objectHit, .objectSelect:
            return .ignored

        case .objectPartHit:
            // TODO: Open editor for the part hit: primary/secondary label, error indicator
            return .handled
        }
    }
    
    func dragCancel(_ event: ToolEvent) -> EventDisposition {
        cleanUp()
        document.endInteractivePreview()
        
        if state == .idle { return .ignored }
        else { return .handled }
    }
    
    // MARK: - Object Move
    
    func previewSelectionMove(screenDelta: Vector2D) {
        guard let scene = canvas.scene,
              let plane = document.world.plane
        else { return }
        let selection = document.selection

        var dependentEdges: Set<PoieticCore.ObjectID> = Set()
        let worldDelta = screenDelta / canvas.zoomLevel

        for objectID in selection {
            guard let entity = world.entity(objectID),
                  let block: DiagramBlock = entity.component()
            else { continue }
            
            entity.setComponent(DirtyContent.geometry)
            
            var preview: PreviewPositionComponent
            preview = entity.component() ?? PreviewPositionComponent(position: block.position)
            preview.position += worldDelta
            entity.setComponent(preview)
            entity.modifyOrSet(default: DirtyContent.geometry) {
                $0.insert(.geometry)
            }
            
            let deps = plane.dependentEdges(objectID)
            dependentEdges.formUnion(deps)
        }
        
        for objectID in selection {
            guard let entity = world.entity(objectID),
                  let connector: DiagramConnector = entity.component(),
                  !connector.midpoints.isEmpty
            else { continue }

            var preview: PreviewMidpoints = entity.component()
                        ??  PreviewMidpoints(midpoints: connector.midpoints)
            
            preview.midpoints = preview.midpoints.map { $0 + worldDelta }
            entity.setComponent(preview)
            entity.modifyOrSet(default: DirtyContent.geometry) {
                $0.insert(.geometry)
            }
        }
        
        for objectID in dependentEdges {
            guard let entity = world.entity(objectID) else { continue }
            entity.modifyOrSet(default: DirtyContent.geometry) {
                $0.insert(.geometry)
            }
        }
        
        scene.modifyOrSet(default: DirtyContent.geometry) {
            $0.insert(.geometry)
        }
        
        document.queueInteractivePreviewUpdate()
    }
    
    func finalizeSelectionMove(_ selection: Selection, by designDelta: Vector2D) {
        let trans = document.createOrReuseTransaction()

        for id in selection {
            guard trans.contains(id) else { continue }
            let object = trans.mutate(id)
            moveObject(object, by: designDelta)
        }

        cleanUp()
    }

    func moveObject(_ object: TransientObject, by designDelta: Vector2D) {
        if object.type.hasTrait(DiagramDomain.Traits.DiagramBlock) {
            object.position = (object.position ?? .zero) + designDelta
        }
        else if object.type.hasTrait(DiagramDomain.Traits.DiagramConnector) {
            guard let midpoints: [Point] = object["midpoints"],
                  !midpoints.isEmpty
            else { return }
            
            let movedMidpoints = midpoints.map { $0 + designDelta }
            object["midpoints"] = Variant(movedMidpoints)
        }
    }
    
    // MARK: - Clean-up
    
    func cleanUp() {
        world.removeComponentForAll(PreviewPositionComponent.self)
        world.removeComponentForAll(PreviewMidpoints.self)
    }
}

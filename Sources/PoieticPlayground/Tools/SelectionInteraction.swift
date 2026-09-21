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
    
    enum State {
        /// Nothing hit, initial state
        case idle
        /// Direct hit of a single object, typically a block or a connector.
        case objectHit
        /// Object selection initiated.
        case objectSelect
        /// Dragging selection around.
        case objectMove
        /// Handle that can be moved was hit.
        case handleEngaged(RuntimeID)
        /// Dragging handle around.
        case handleMove(RuntimeID)
        /// Object part was hit, such as label or issue indicator.
        case objectPartHit(RuntimeID, CanvasHitTarget.Kind.ObjectPart)
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
        let target = canvas.hitTarget(screenPosition: event.screenPos)
        let selection = document.selection

        switch target?.kind {
        case .none:
            document.changeSelection(.removeAll)
            state = .objectSelect
            removeHandles()
            return .handled

        case .object(let runtimeID, .body):
            // TODO: Defer opening of context menu on inputEnded or move context menu out of the tool
            guard let objectID = world.entity(runtimeID)?.objectID
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
            self.removeHandles()
            self.createHandles()

            state = .objectHit

        case .object(let runtimeID, .issueIndicator):
            self.removeHandles()
            state = .idle
            guard let objectID = world.entity(runtimeID)?.objectID else { break }
            context.openIssues(for: objectID)

        case .object(let runtimeID, let part):
            self.removeHandles()
            state = .objectPartHit(runtimeID, part)

        case .handle(let runtimeID):
            state = .handleEngaged(runtimeID)
        }
        
        switch state {
        case .idle: return .handled
        default: return .engaged
        }

    }
    func dragStart(_ event: ToolEvent) -> EventDisposition {
//        TODO: popupManager?.closeInlinePopup()
        switch state {
        case .idle, .objectSelect:
            return .ignored
        case .objectHit, .objectMove, .objectPartHit:
            document.beginInteractivePreview()
            previewSelectionMove(screenDelta: event.delta)
            state = .objectMove
            
        case .handleEngaged(let handleID), .handleMove(let handleID):
            document.beginInteractivePreview()
            dragHandle(handleID, screenDelta: event.delta)
            state = .handleMove(handleID)
        }
        return .engaged
    }
    func dragMove(_ event: ToolEvent) -> EventDisposition {

//        TODO: popupManager?.closeInlinePopup()
        switch state {
        case .idle: break
        case .objectSelect: break
        case .objectHit, .objectMove, .objectPartHit:
            previewSelectionMove(screenDelta: event.delta)
            syncHandlesToPreview()
            state = .objectMove
            
        case .handleEngaged(let handleID), .handleMove(let handleID):
            dragHandle(handleID, screenDelta: event.delta)
            state = .handleMove(handleID)
        }

        return .engaged
    }

    func dragEnd(_ event: ToolEvent) -> EventDisposition {
        defer {
            state = .idle
        }
        // TODO: Mouse cursors
        let screenDelta = event.screenPos - self.dragStartScreenPos
        let worldDelta = Vector2D(screenDelta) / canvas.zoomLevel

        switch state {
        case .objectMove:
            finalizeSelectionMove(document.selection, by: worldDelta)

        case .handleMove(let handleID):
            guard let handle = document.world.entity(handleID) else { break }
            let worldPosition: Vector2D = canvas.screenToWorld(event.screenPos)
            finalizeHandleMove(handle, finalPosition: worldPosition, totalDelta: worldDelta)
            state = .handleMove(handleID)

        case .idle, .objectHit, .objectSelect, .handleEngaged: break

        case .objectPartHit:
            // TODO: Open editor for the part hit: primary/secondary label, error indicator
            break
        }
        document.endInteractivePreview()
        return .handled
    }
    func dragCancel(_ event: ToolEvent) -> EventDisposition {
        cleanUp()
        document.endInteractivePreview()
        return .handled
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
    

    // MARK: - Handle Drag
    /// Create handles for selected object.
    ///
    /// - Note: Currently handles are supported only for selection of one object.
    func createHandles() {
        guard let objectID = document.selection.selectionOfOne(),
              let entity = world.entity(objectID)
        else { return }

        // Dispatch by handle type
        if entity.contains(DiagramConnector.self) {
            createMidpointHandles(entity)
        }
        // ... create other handle types
    }
    
    func createMidpointHandles(_ entity: RuntimeEntity) {
        guard let connector: DiagramConnector = entity.component(),
              let scene = canvas.scene
        else { return }
        
        let style = canvas.style
        let handleSize = style.metric(.handleSize, default: CanvasHandle.DefaultSize)
        
        let preview: PreviewMidpoints? = entity.component()
        let midpoints = preview?.midpoints ?? connector.midpoints
        
        if midpoints.isEmpty {
            guard let origin = world.entity(connector.originID),
                  let originBlock: DiagramBlock = origin.component(),
                  let target = world.entity(connector.targetID),
                  let targetBlock: DiagramBlock = target.component()
            else { return }

            let segment = LineSegment(from: originBlock.position, to: targetBlock.position)
            let midpoint = segment.midpoint

            createMidpointHandle(worldPosition: midpoint,
                                 scenePosition: canvas.worldToScene(midpoint),
                                 index: 0,
                                 handles: entity,
                                 parent: scene,
                                 size: handleSize)
        }
        else {
            for (index, point) in midpoints.enumerated() {
                createMidpointHandle(worldPosition: point,
                                     scenePosition: canvas.worldToScene(point),
                                     index: index,
                                     handles: entity,
                                     parent: scene,
                                     size: handleSize)
            }
        }
    }
    
    func createMidpointHandle(worldPosition: Vector2D,
                              scenePosition: Vector2D,
                              index: Int,
                              handles handledEntity: RuntimeEntity,
                              parent: RuntimeEntity,
                              size: Double)
    {
        let handle = world.spawn(
            SceneNode(),
            CanvasHandle(position: worldPosition, kind: .midpoint(index)),
            CollisionShape(position: .zero, shape: .circle(size / 2.0)),
            PositionComponent(position: scenePosition),
            CanvasNodeStyle(class: .handle),
            Interactivity.interactive,
        )
        handle.relate(Handles(), to: handledEntity)
        handle.relate(ChildOf(), to: parent)
    }
    
    func syncHandlesToPreview() {
        for (entity, var handle) in world.query(CanvasHandle.self) {
            guard let target = entity.target(Handles.self),
                  let preview: PreviewMidpoints = target.component(),
                  case .midpoint(let index) = handle.kind,
                  index < preview.midpoints.count
            else { continue }
            
            let pos = preview.midpoints[index]
            handle.worldPosition = pos
            entity.setComponent(handle)
            entity.setComponent(PositionComponent(position: canvas.worldToScene(pos)))
        }
    }

    func dragHandle(_ handleRuntimeID: RuntimeID, screenDelta: Vector2D) {
        guard let handle = document.world.entity(handleRuntimeID),
              var component: CanvasHandle = handle.component()
        else { return }
        let worldDelta = screenDelta / canvas.zoomLevel
        component.worldPosition += worldDelta
        handle.setComponent(component)
        handle.setComponent(PositionComponent(position: canvas.worldToScene(component.worldPosition)))

        switch component.kind {
        case .midpoint(let index):
            guard let target: RuntimeEntity = handle.target(Handles.self) else { break }
            dragMidpointHandle(target, index: index, currentPosition: component.worldPosition, currentDelta: worldDelta)
            target.setComponent(DirtyContent.geometry)
        }
        
        document.queueInteractivePreviewUpdate()
    }
    
    /// Reflect handle position to connector preview.
    ///
    func dragMidpointHandle(_ target: RuntimeEntity, index: Int, currentPosition: Vector2D, currentDelta: Vector2D) {
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
    
    func finalizeHandleMove(_ handle: RuntimeEntity, finalPosition: Vector2D, totalDelta: Vector2D) {
        guard let component: CanvasHandle = handle.component()
        else { return }

        switch component.kind {
        case .midpoint(let index):
            guard let target: RuntimeEntity = handle.target(Handles.self) else { break }
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
    // MARK: - Clean-up
    
    func cleanUp() {
        world.removeComponentForAll(PreviewPositionComponent.self)
        world.removeComponentForAll(PreviewMidpoints.self)
    }
    
    func removeHandles() {
        for (runtimeID, _) in world.query(CanvasHandle.self) {
            world.despawn(runtimeID)
        }
    }

    
}

//
//  ConnectInteraction.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 21/09/2026.
//

import PoieticCore
import Diagramming

class ConnectInteraction: ToolInteraction {
    unowned let document: Document
    unowned let canvas: DiagramCanvas
    
    var world: World { document.world }
    var checker: ConstraintChecker? = nil  // TODO: Not the best location for this

    let selectedType: String?

    enum State {
        case idle
        case connecting
    }

    var state: State = .idle
    var intendedConnector: RuntimeEntity? = nil
    /// Invisible scene node to serve as a connector target.
    ///
    /// Required to make connector intent valid so that we can compute connector geometry.
    var connectorHandle: RuntimeEntity? = nil

    init(document: Document, canvas: DiagramCanvas, selectedType: String?) {
        self.document = document
        self.canvas = canvas
        self.selectedType = selectedType
    }
    
    func begin() {
        document.changeSelection(.removeAll)
        self.checker = ConstraintChecker(document.design.metamodel)
    }
    
    func end () {
        removeDragConnector()
        document.endInteractivePreview()
        intendedConnector = nil
        connectorHandle = nil
    }
    
    func handleEvent(_ event: ToolEvent) -> EventDisposition {
        switch event.type {
        case .dragStart: return self.dragStart(event)
        case .dragMove: return self.dragMove(event)
        case .dragEnd: return self.dragEnd(event)
        case .dragCancel: return self.dragCancel(event)
        default: return .ignored
        }
    }

    func dragStart(_ event: ToolEvent) -> EventDisposition{
        guard event.triggerButton == .left else { return .ignored }
        guard let scene = canvas.scene,
              let hitObject = canvas.hitObject(screenPosition: event.screenPos),
              world.contains(hitObject.sceneNode),
              let typeName = selectedType,
              let type = document.design.metamodel.objectType(name: typeName)
        else {
            state = .idle
            return .ignored
        }
        let worldPosition: Vector2D = canvas.screenToWorld(event.screenPos)
        let scenePosition: Vector2D = canvas.worldToScene(worldPosition)
        
        // Clean-up, just to be safe
        self.removeDragConnector()

        let notation: Notation = world.singleton() ?? Notation.DefaultNotation
        // TODO: Use notation rules
        // let rules: NotationRules = world.singleton() ?? NotationRules()
        let glyph = notation.connectorGlyph(type.name)

        // -- Handle --
        let handle = world.spawn(
            SceneNode(),
            PositionComponent(position: scenePosition)
        )
        handle.relate(ChildOf(), to: scene)
        self.connectorHandle = handle
        
        // -- Connector --
        let connector = world.spawn(
            SceneNode(),
            ConnectorSceneNode(),
            glyph,
            ConnectorIntent(type:type),
            CanvasNodeStyle(class: .connector, modifiers: .preview),
            DirtyContent.geometry,
        )
        connector.relate(ChildOf(), to: scene)
        connector.relate(MemberOf(), to: scene)
        connector.relate(ConnectorSceneNode.Origin(),to: hitObject.sceneNode)
        connector.relate(ConnectorSceneNode.Target(),to: handle)

        self.intendedConnector = connector

        // -- Begin preview --
        document.beginInteractivePreview()

        self.state = .connecting
        return .engaged
    }
    
    func dragMove(_ event: ToolEvent) -> EventDisposition {
        guard state == .connecting,
              let intendedConnector,
              let connectorHandle,
              let intent: ConnectorIntent = intendedConnector.component()
        else { return .ignored}
        
        // -- Handle --
        let worldPosition: Vector2D = canvas.screenToWorld(event.screenPos)
        let scenePosition: Vector2D = canvas.worldToScene(worldPosition)

        connectorHandle.setComponent(PositionComponent(position: scenePosition))
        connectorHandle.setComponent(DirtyContent.geometry)
        intendedConnector.setComponent(DirtyContent.geometry)

        // -- Connector Intent --
        let newTargetID: RuntimeID?

        if let target = canvas.hitObject(screenPosition: event.screenPos),
           isValidTarget(target.sceneNode)
        {
            newTargetID = target.sceneNode
        }
        else {
            newTargetID = nil
        }

        let oldTarget: RuntimeEntity? = intendedConnector.target(ConnectorSceneNode.Target.self)
        if let newTargetID {
            intendedConnector.relate(ConnectorSceneNode.Target(), to: newTargetID)
        }
        else {
            intendedConnector.relate(ConnectorSceneNode.Target(), to: connectorHandle)
        }

        if let oldTarget {
            oldTarget.modify(CanvasNodeStyle.self) {
                $0.modifiers.subtract(.allowedMask)
            }
        }

        if let newTargetID,
           let newTarget = world.entity(newTargetID)
        {
            let targetAllowed = canConnect(type: intent.type)
            newTarget.modify(CanvasNodeStyle.self) {
                if targetAllowed {
                    $0.modifiers.insert(.allowed)
                    $0.modifiers.remove(.notAllowed)
                }
                else {
                    $0.modifiers.remove(.allowed)
                    $0.modifiers.insert(.notAllowed)
                }
            }
        }

        document.queueInteractivePreviewUpdate()
        return .engaged
    }

    func dragEnd(_ event: ToolEvent) -> EventDisposition {
        defer {
            self.state = .idle
            removeDragConnector()
            document.endInteractivePreview()
        }

        guard let intendedConnector,
              let intent: ConnectorIntent = intendedConnector.component(),
              let origin: RuntimeEntity = intendedConnector.target(ConnectorSceneNode.Origin.self),
              let hitObject = canvas.hitObject(screenPosition: event.screenPos)
        else { return .ignored }
        
        if canConnect(type: intent.type) {
            createConnection(type: intent.type, from: origin.runtimeID, to: hitObject.designObject)
        }

        return .handled
    }
    
    func dragCancel(_ event: ToolEvent) -> EventDisposition {
        self.state = .idle
        removeDragConnector()
        document.endInteractivePreview()
        return .handled
    }

    /// Returns true whether given entity is a valid connector target – a block.
    ///
    /// - Note: This is a different flag from being allowed or not. Target can be valid (a block)
    ///   but can still be not allowed. Invalid target is another connector for example.
    ///
    func isValidTarget(_ runtimeID: RuntimeID) -> Bool {
        guard let entity = world.entity(runtimeID)
        else { return false }
        
        return entity.contains(BlockSceneNode.self)
    }
    
    func representedObjectsOfIntent() -> (origin: ObjectID, target: ObjectID)? {
        guard let intent = self.intendedConnector,
              let originSceneNode: RuntimeEntity = intent.target(ConnectorSceneNode.Origin.self),
              let origin = originSceneNode.target(RepresentationOf.self),
              let originID = origin.objectID,
              let targetSceneNode: RuntimeEntity = intent.target(ConnectorSceneNode.Target.self),
              let target = targetSceneNode.target(RepresentationOf.self),
              let targetID = target.objectID
        else {
            return nil
        }
        return (origin: originID, target: targetID)
    }
    
    func canConnect(type: ObjectType) -> Bool
    {
        guard let checker,
              let plane = document.world.plane,
              let (originObjectID, targetObjectID) = representedObjectsOfIntent()
        else { return false }
        
        return checker.canConnect(type: type, from: originObjectID, to: targetObjectID, in: plane)
    }
    func createConnection(type: ObjectType, from originRuntimeID: RuntimeID, to targetRuntimeID: RuntimeID) {
        guard let (originObjectID, targetObjectID) = representedObjectsOfIntent()
        else { return }
        
        let trans = document.createOrReuseTransaction()
        trans.createEdge(type, origin: originObjectID, target: targetObjectID)
    }

    func removeDragConnector() {
        if let intendedConnector {
            if let target: RuntimeEntity = intendedConnector.target(ConnectorSceneNode.Target.self) {
                target.modify(CanvasNodeStyle.self) {
                    $0.modifiers.subtract(.allowedMask)
                }
            }
            intendedConnector.despawn()
            self.intendedConnector = nil
        }
        if let connectorHandle {
            connectorHandle.despawn()
            self.connectorHandle = nil
        }
    }
}

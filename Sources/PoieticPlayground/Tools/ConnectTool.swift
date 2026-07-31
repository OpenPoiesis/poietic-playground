//
//  ConnectTool.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 05/02/2026.
//

import CIimgui
import Diagramming
import PoieticCore

// TODO: This tool is mostly hard-coded to the stock-flow metamodel

class ConnectTool: CanvasTool {
    // TODO: Implement the tool (empty stub for now)
    override var name: String { "connect"}
    override var iconKey: IconKey { .connect }
    override var hasObjectPalette: Bool { true }

    enum State {
        case idle
        case connecting
    }

    var state: State = .idle
    var checker: ConstraintChecker? = nil  // TODO: Not the best location for this
    var intendedConnector: RuntimeEntity? = nil
    /// Invisible scene node to serve as a connector target.
    ///
    /// Required to make connector intent valid so that we can compute connector geometry.
    var connectorHandle: RuntimeEntity? = nil
    
    var palette: ObjectPalette? = nil

    override func activate() {
        guard let document,
              let notation: Notation = document.world.singleton()
        else { return }

        document.changeSelection(.removeAll)
        self.checker = ConstraintChecker(document.design.metamodel)
        
        var items: [PaletteItem] = []
        
        for type in connectableTypes() {
            var texture: TextureHandle? = nil
            switch type.name {
            case "Parameter":
                texture = InterfaceStyle.current.texture(forIcon: .arrowParameter)
            case "Flow":
                texture = InterfaceStyle.current.texture(forIcon: .arrowOutlined)
            default:
                texture = nil
            }
            guard let texture else {
                print("NO TEXTURE FOR: \(type.name)")
                continue
            }
            let item = PaletteItem(identifier: type.name, image: .texture(texture), label: type.label)
            items.append(item)
        }

        self.palette = ObjectPalette(columns: 2, items: items)

    }
    
    override func drawPalette() {
        guard let palette else { return }
        palette.draw()
    }
    
    func connectableTypes() -> [ObjectType] {
        // TODO: Read from metamodel
        // TODO: Use connector glyphs and make the object palette single column and wide
        return [ObjectType.Parameter, ObjectType.Flow]
    }
    
    override func handleEvent(_ event: ToolEvent) -> EngagementResult {
        switch event.type {
        case .dragStart: return self.dragStart(event)
        case .dragMove: return self.dragMove(event)
        case .dragEnd: return self.dragEnd(event)
        case .dragCancel: return self.dragCancel(event)
        default: return .pass
        }
    }

    func dragStart(_ event: ToolEvent) -> EngagementResult{
        guard event.triggerButton == .left else { return .pass }
        guard let canvas,
              let document,
              let scene = canvas.scene,
              let originHit = canvas.hitTarget(screenPosition: event.screenPos),
              case .object(let originID, _) = originHit,
              let typeName = palette?.selectedIdentifier,
              let type = document.design.metamodel.objectType(name: typeName)
        else {
            state = .idle
            return .pass
        }
        let worldPosition: Vector2D = canvas.screenToWorld(event.screenPos)
        let scenePosition: Vector2D = canvas.worldToScene(worldPosition)
        
        // Clean-up, just to be safe
        self.removeDragConnector()

        print("Creating drag connector of type \(type), origin: \(originID)")

        let notation: Notation = world.singleton() ?? Notation.DefaultNotation
        // TODO: Use notation rules
        // let rules: NotationRules = world.singleton() ?? NotationRules()
        let glyph = notation.connectorGlyph(type.name)

        // -- Handle --
        let handle = world.spawn(
            DiagramSceneNode(),
            PositionComponent(position: scenePosition)
        )
        handle.relate(ChildOf(), to: scene)
        self.connectorHandle = handle
        
        // -- Connector --
        let connector = world.spawn(
            DiagramSceneNode(),
            ConnectorCanvasNode(),
            glyph,
            ConnectorIntent(type:type, targetAllowed: false),
            CanvasNodeStyle(class: .connector, modifiers: .preview)
        )
        connector.relate(ChildOf(), to: scene)
        connector.relate(ConnectorCanvasNode.Origin(),to: originID)
        connector.relate(ConnectorCanvasNode.Target(),to: handle)

        self.intendedConnector = connector

        // -- Begin preview --
        document.beginInteractivePreview()

        self.state = .connecting
        return .engaged
    }
    
    func dragMove(_ event: ToolEvent) -> EngagementResult {
        guard state == .connecting,
              let canvas,
              let document,
              let intendedConnector,
              let connectorHandle,
              let intent: ConnectorIntent = intendedConnector.component(),
              let origin: RuntimeEntity = intendedConnector.target(ConnectorCanvasNode.Origin.self)
        else { return .pass}
        
        // -- Handle --
        let worldPosition: Vector2D = canvas.screenToWorld(event.screenPos)
        let scenePosition: Vector2D = canvas.worldToScene(worldPosition)

        connectorHandle.setComponent(PositionComponent(position: scenePosition))
        connectorHandle.modifyOrSet(default: DirtyContent.geometry) {
            $0.insert(.geometry)
        }

        // -- Connector Intent --
        let newTargetID: RuntimeID?
        let targetAllowed: Bool

        if let target = canvas.hitTarget(screenPosition: event.screenPos),
           case .object(let targetID, _) = target
        {
            newTargetID = targetID
            targetAllowed = canConnect(type: intent.type, from: origin.runtimeID, to: targetID)
        }
        else {
            newTargetID = nil
            targetAllowed = true
        }

        let oldTarget: RuntimeEntity? = intendedConnector.target(ConnectorCanvasNode.Target.self)

        let newIntent = ConnectorIntent(type: intent.type,
                                        targetAllowed: targetAllowed)

        intendedConnector.setComponent(newIntent)
        intendedConnector.modifyOrSet(default: DirtyContent.geometry) {
            $0.insert(.geometry)
        }

        if let newTargetID {
            intendedConnector.relate(ConnectorCanvasNode.Target(), to: newTargetID)
        }
        else {
            intendedConnector.relate(ConnectorCanvasNode.Target(), to: connectorHandle)
        }

        if let oldTarget {
            oldTarget.modify(CanvasNodeStyle.self) {
                $0.modifiers.subtract(.allowedMask)
            }
            // TODO: [REFACTORING] Which content set dirty?
            // TODO: [REFACTORING] Do the same with the new target
//            oldTarget.modifyOrSet(default: Diagram.DirtyContent.???) {
//                $0.insert(.geometry)
//            }
        }

        if let newTargetID,
           let newTarget = world.entity(newTargetID)
        {
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

    func dragEnd(_ event: ToolEvent) -> EngagementResult {
        defer {
            self.state = .idle
            removeDragConnector()
        }

        guard let intendedConnector,
              let canvas,
              let document,
              let intent: ConnectorIntent = intendedConnector.component(),
              let origin: RuntimeEntity = intendedConnector.target(ConnectorCanvasNode.Origin.self),
              let hitTarget = canvas.hitTarget(screenPosition: event.screenPos),
              case .object(let targetID, _) = hitTarget
        else { return .pass }
        
        if canConnect(type: intent.type, from: origin.runtimeID, to: targetID) {
            createConnection(type: intent.type, from: origin.runtimeID, to: targetID)
        }

        document.endInteractivePreview()
        print("Drag concluded.")
        return .consumed
    }
    
    func dragCancel(_ event: ToolEvent) -> EngagementResult {
        self.state = .idle
        removeDragConnector()
        document?.endInteractivePreview()
        return .consumed
    }

    func canConnect(type: ObjectType, from originID: RuntimeID, to targetID: RuntimeID) -> Bool {
        guard let document,
              let checker,
              let frame = document.world.frame,
              let originObjectID = document.world.entity(originID)?.objectID,
              let targetObjectID = document.world.entity(targetID)?.objectID
        else { return false }
        
        return checker.canConnect(type: type, from: originObjectID, to: targetObjectID, in: frame)
    }
    func createConnection(type: ObjectType, from originRuntimeID: RuntimeID, to targetRuntimeID: RuntimeID) {
        guard let document,
              let originObjectID = document.world.entity(originRuntimeID)?.objectID,
              let targetObjectID = document.world.entity(targetRuntimeID)?.objectID
        else { return }
        let trans = document.createOrReuseTransaction()
        trans.createEdge(type, origin: originObjectID, target: targetObjectID)
    }

    func removeDragConnector() {
        if let intendedConnector {
            if let target: RuntimeEntity = intendedConnector.target(ConnectorCanvasNode.Target.self) {
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

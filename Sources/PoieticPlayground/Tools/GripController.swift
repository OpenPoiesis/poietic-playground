//
//  GripController.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 23/09/2026.
//

// NOTE: This is incubated. Might be converted to System(s)

import PoieticCore
import Diagramming

@MainActor
class GripController {
    unowned var canvas: DiagramCanvas?
    unowned var world: World?

    var selection: Selection? { world?.singleton() }
    var scene: RuntimeEntity? { canvas?.scene }
    var grips: [(RuntimeEntity, Grip)] {
        guard let scene else { return [] }
        
        return scene.children.compactMap {
            guard let grip: Grip = $0.component()
            else { return nil }
            return ($0, grip)
        }
    }
    
    init() {
        self.canvas = nil
        self.world = nil
    }
    
    func bind(canvas: DiagramCanvas, world: World) {
        self.canvas = canvas
        self.world = world
    }
    
    func unbind() {
        self.canvas = nil
        self.world = nil
    }
    
    func createAll() {
        removeMidpointGrips()
        createMidpointGrips()
    }
    
    func syncAll() {
        syncMidpointGrips()
    }
}

// MARK: - Connector Midpoints

// TODO: Evolve this into a handle provider
extension GripController {
    func createMidpointGrips() {
        guard let world,
              let selection,
              let objectID = selection.selectionOfOne(),
              let entity = world.entity(objectID)
        else { return }
        createMidpointGrips(for: entity)
    }
    
    func createMidpointGrips(for entity: RuntimeEntity) {
        guard let canvas,
              let world,
              let connector: DiagramConnector = entity.component(),
              let scene = canvas.scene
        else { return }
        
        let style = canvas.style
        let handleSize = style.metric(.handleSize, default: Grip.DefaultSize)
        
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

            createMidpointGrip(worldPosition: midpoint,
                               scenePosition: canvas.worldToScene(midpoint),
                               index: 0,
                               target: entity,
                               parent: scene,
                               size: handleSize)
        }
        else {
            for (index, point) in midpoints.enumerated() {
                createMidpointGrip(worldPosition: point,
                                   scenePosition: canvas.worldToScene(point),
                                   index: index,
                                   target: entity,
                                   parent: scene,
                                   size: handleSize)
            }
        }
    }
    
    func createMidpointGrip(worldPosition: Vector2D,
                            scenePosition: Vector2D,
                            index: Int,
                            target: RuntimeEntity,
                            parent: RuntimeEntity,
                            size: Double)
    {
        guard let world else { return }
        let handle = world.spawn(
            SceneNode(),
            Grip(position: worldPosition, key: .connectorMidpoint(index)),
            CollisionShape(position: .zero, shape: .circle(size / 2.0)),
            PositionComponent(position: scenePosition),
            CanvasNodeStyle(class: .handle),
            Interactivity.interactive,
            InteractionDirty(),
        )
        handle.relate(GripOf(), to: target)
        handle.relate(ChildOf(), to: parent)
    }
    
    func syncMidpointGrips() {
        guard let canvas
        else { return }
        
        for (entity, var grip) in self.grips {
            guard let target = entity.target(GripOf.self),
                  let preview: PreviewMidpoints = target.component(),
                  case .connectorMidpoint(let index) = grip.key,
                  index < preview.midpoints.count
            else { continue }
            
            let pos = preview.midpoints[index]
            grip.worldPosition = pos
            entity.setComponent(grip)
            entity.setComponent(PositionComponent(position: canvas.worldToScene(pos)))
            entity.setComponent(InteractionDirty())
        }
    }

    func removeMidpointGrips() {
        guard let world else { return }
        
        for (runtimeID, _) in grips {
            world.despawn(runtimeID)
        }
    }
}

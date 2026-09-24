//
//  DiagramCanvas+hitTarget.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 24/09/2026.
//

import PoieticCore
import Diagramming

extension DiagramCanvas {
    func hitObject(screenPosition: Vector2D) -> CanvasObjectHit? {
        guard let scene else { return nil }
        
        let scenePosition = worldToScene(screenToWorld(screenPosition))
        let radius = DiagramCanvas.DefaultHitRadius / zoomLevel
        
        guard let hitEntity = hitTest(node: scene, scenePosition: scenePosition, radius: radius),
              let parent: RuntimeEntity = hitEntity.target(ChildOf.self)
        else { return nil }

        // Resolve the design entity: for blocks/connectors it's the hit entity itself;
        // for labels/indicators it is the parent block.
        let designEntity: RuntimeEntity?

        if hitEntity.contains(BlockSceneNode.self) || hitEntity.contains(ConnectorSceneNode.self) {
            designEntity = hitEntity.target(RepresentationOf.self)
        }
        else {  // Label, indicator, etc. — parent is the block scene node
            designEntity = parent.target(RepresentationOf.self)
        }

        guard let designEntity else { return nil }
        
        let part: CanvasObjectHit.ObjectPart
        
        if parent.relates(SceneNode.PrimaryLabel.self, to: hitEntity) {
            part = .primaryLabel
        } else if parent.relates(SceneNode.SecondaryLabel.self, to: hitEntity) {
            part = .secondaryLabel
        } else if hitEntity.contains(IssueIndicatorSceneNode.self) {
            part = .issueIndicator
        } else if hitEntity.contains(BlockSceneNode.self) || hitEntity.contains(ConnectorSceneNode.self) {
            part = .body
        }
        else {
            return nil
        }
        
        return CanvasObjectHit(sceneNode: hitEntity.runtimeID , designObject: designEntity.runtimeID, part: part)
    }
    
    func hitTest(node: RuntimeEntity, scenePosition: Vector2D, radius: Double) -> RuntimeEntity? {
        // FIXME: We need z-index ordering
        for child in node.children where !child.contains(Grip.self) {
            if let region: TouchRegion = child.component(),
               region.isHit(at: scenePosition, radius: radius)
            {
                return child
            }
            if let found = hitTest(node: child, scenePosition: scenePosition, radius: radius) {
                return found
            }
        }
        return nil
    }

    func hitGrip(screenPosition: Vector2D) -> CanvasGripHit? {
        guard let scene else { return nil }
        
        let scenePosition = worldToScene(screenToWorld(screenPosition))
        let radius = DiagramCanvas.DefaultHitRadius / zoomLevel

        for grip in scene.children where grip.contains(Grip.self) {
            guard let region: TouchRegion = grip.component(),
                  region.isHit(at: scenePosition, radius: radius),
                  let component: Grip = grip.component()
            else { continue }

            return CanvasGripHit(runtimeID: grip.runtimeID, grip: component)
        }
        
        return nil
    }
    
}

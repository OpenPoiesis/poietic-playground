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
        guard let presentation else { return nil }
        
        let localPosition = worldToPresentation(screenToWorld(screenPosition))
        let radius = DiagramCanvas.DefaultHitRadius / zoomLevel
        
        guard let hitEntity = hitTest(node: presentation, presentationPosition: localPosition, radius: radius),
              let parent: RuntimeEntity = hitEntity.target(ChildOf.self)
        else { return nil }

        // Resolve the design entity: for blocks/connectors it's the hit entity itself;
        // for labels/indicators it is the parent block.
        let designEntity: RuntimeEntity?

        if hitEntity.contains(BlockNode.self) || hitEntity.contains(ConnectorNode.self) {
            designEntity = hitEntity.target(RepresentationOf.self)
        }
        else {  // Label, indicator, etc. — parent is the block presentation node
            designEntity = parent.target(RepresentationOf.self)
        }

        guard let designEntity else { return nil }
        
        let part: CanvasObjectHit.ObjectPart
        
        if parent.relates(PresentationNode.PrimaryLabel.self, to: hitEntity) {
            part = .primaryLabel
        } else if parent.relates(PresentationNode.SecondaryLabel.self, to: hitEntity) {
            part = .secondaryLabel
        } else if hitEntity.contains(IssueIndicatorNode.self) {
            part = .issueIndicator
        } else if hitEntity.contains(BlockNode.self) || hitEntity.contains(ConnectorNode.self) {
            part = .body
        }
        else {
            return nil
        }
        
        return CanvasObjectHit(presentationNode: hitEntity.runtimeID , designObject: designEntity.runtimeID, part: part)
    }
    
    func hitTest(node: RuntimeEntity, presentationPosition: Vector2D, radius: Double) -> RuntimeEntity? {
        // FIXME: We need z-index ordering
        for child in node.children where !child.contains(Grip.self) {
            if let region: HitRegion = child.component(),
               region.isHit(at: presentationPosition, radius: radius)
            {
                return child
            }
            if let found = hitTest(node: child, presentationPosition: presentationPosition, radius: radius) {
                return found
            }
        }
        return nil
    }

    func hitGrip(screenPosition: Vector2D) -> CanvasGripHit? {
        guard let presentation else { return nil }
        
        let localPosition = worldToPresentation(screenToWorld(screenPosition))
        let radius = DiagramCanvas.DefaultHitRadius / zoomLevel

        for grip in presentation.children where grip.contains(Grip.self) {
            guard let region: HitRegion = grip.component(),
                  region.isHit(at: localPosition, radius: radius),
                  let component: Grip = grip.component()
            else { continue }

            return CanvasGripHit(runtimeID: grip.runtimeID, grip: component)
        }
        
        return nil
    }
    
}

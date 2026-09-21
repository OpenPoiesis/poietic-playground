//
//  PlacementInteraction.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 21/09/2026.
//

import PoieticCore
import Diagramming

class PlacementInteraction: ToolInteraction {
    
    unowned let document: Document
    unowned let canvas: DiagramCanvas
    
    var world: World { document.world }

    let selectedType: String?
    var blockIntent: RuntimeEntity? = nil
    
    init(document: Document, canvas: DiagramCanvas, selectedType: String?) {
        self.document = document
        self.canvas = canvas
        self.selectedType = selectedType
    }
    
    func begin() {
        document.changeSelection(.removeAll)
    }

    func end () {
        removeBlockIntent()
        document.endInteractivePreview()
    }

    func createBlockIntent(position: Vector2D, typeName: String) {
        guard let scene = canvas.scene,
              let notation: Notation = world.singleton(),
              let type = document.design.metamodel.objectType(name: typeName)
        else { return }

        let scenePos = canvas.worldToScene(position)
                                                                                                                                                                                                                
        removeBlockIntent()
                                                                                                                                                                                                                
        let blockNode = world.spawn(
            BlockIntent(type: type),
            SceneNode(),
            BlockSceneNode(),
            PositionComponent(position: scenePos),
            CanvasNodeStyle(class: .block, modifiers: .preview),
            DirtyContent.geometry,
            Visibility.visible,
        )
        blockNode.relate(ChildOf(), to: scene)
        blockNode.relate(MemberOf(), to: scene)

        let pictogram = notation.pictogram(type.name)

        let pictogramNode = world.spawn(
            SceneNode(),
            PictogramSceneNode(pictogram: pictogram),
            PositionComponent(position: .zero),
            Visibility.visible,
        )
        pictogramNode.relate(ChildOf(), to: blockNode)
        blockNode.relate(SceneNode.Pictogram(), to: pictogramNode)

        self.blockIntent = blockNode
    }

    func removeBlockIntent() {
        guard let blockIntent else { return }
        world.despawn(blockIntent)
        self.blockIntent = nil
    }
    
    func handleEvent(_ event: ToolEvent) -> EventDisposition {
        switch event.type {
        case .hoverStart: return self.hoverStart(event)
        case .pointerMove: return self.pointerMove(event)
        case .hoverEnd: return self.hoverEnd(event)
        case .pointerUp: return self.pointerUp(event)
        default: return .ignored
        }
    }
    func hoverStart(_ event: ToolEvent) -> EventDisposition {
        guard let typeName = selectedType else { return .ignored }
        
        removeBlockIntent()
        let worldPos: Vector2D = canvas.screenToWorld(event.screenPos)
        createBlockIntent(position: worldPos, typeName: typeName)
        document.beginInteractivePreview()
        document.queueInteractivePreviewUpdate()
        return .ignored
    }
    
    func pointerMove(_ event: ToolEvent) -> EventDisposition {
        guard let blockIntent else { return .ignored }
        
        let worldPos: Vector2D = canvas.screenToWorld(event.screenPos)
        let canvasPos: Vector2D = canvas.worldToScene(worldPos)

        blockIntent.setComponent(PositionComponent(position: canvasPos))
        blockIntent.setComponent(DirtyContent.geometry)
        
        document.queueInteractivePreviewUpdate()
        return .ignored
    }
    
    func hoverEnd(_ event: ToolEvent) -> EventDisposition {
        removeBlockIntent()
        document.queueInteractivePreviewUpdate()
        return .ignored
    }
    
    func pointerUp(_ event: ToolEvent)  -> EventDisposition {
        guard let blockIntent,
              let intent: BlockIntent = blockIntent.component()
        else { return .ignored }
        let worldPos: Vector2D = canvas.screenToWorld(event.screenPos)

        if let objectID = placeObject(type: intent.type, at: worldPos) {
            document.changeSelection(.replaceAllWithOne(objectID))
            context?.switchTool(.selection)
        }
        document.queueInteractivePreviewUpdate()
        document.endInteractivePreview()
        return .handled
    }
    
    func placeObject(type: ObjectType, at position: Vector2D) -> ObjectID? {
        let trans = document.createOrReuseTransaction()
        
        let count = trans.filter(type: type).count
        // TODO: Have a better auto-naming mechanism. Right now the new name might collide, which is somewhat fine - users will get node error (indicated), but easy to spot and fix.
        let name = type.name.toSnakeCase() + String(count)

        let node = trans.createNode(type)
        node.position = position
        node["name"] = Variant(name)
        return node.objectID
    }

    
}

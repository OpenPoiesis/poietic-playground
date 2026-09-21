//
//  PlacementTool.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 05/02/2026.
//

import PoieticCore
import CIimgui
import Diagramming

class PlacementTool: CanvasTool {
    static let IconSize: ImVec2 = ImVec2(60, 40)
    static let PaletteCellSize: ImVec2 = ImVec2(60, 60)

    override var type: CanvasToolType { .placement }
    override var hasObjectPalette: Bool { true }
    override var iconKey: IconKey { .place }
    
    override func paletteItems(in context: ToolContext) -> [PaletteItem] {
        let document = context.document
        let world = document.world

        guard let notation: Notation = world.singleton()
        else { return [] }
        
        var items: [PaletteItem] = []
        
        for type in document.design.metamodel.types {
            guard type.hasTrait(DiagramDomain.Traits.DiagramBlock) else {
                continue
            }
            
            let pictogram = notation.pictogram(type.name)
            let item = PaletteItem(identifier: type.name, image: .pictogram(pictogram), label: type.label)
            items.append(item)
        }

        return items
    }

    override func makeInteraction(context: ToolContext) -> any ToolInteraction {
        return PlacementInteraction(context: context, selectedType: self.selectedPaletteItem)
    }
}

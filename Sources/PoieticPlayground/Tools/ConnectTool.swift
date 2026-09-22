//
//  ConnectTool.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 05/02/2026.
//

import CIimgui
import Diagramming
import PoieticCore
import PoieticFlows

// TODO: This tool is mostly hard-coded to the stock-flow metamodel
class ConnectTool: CanvasTool {
    static let type: CanvasToolType = .connect
    static let iconKey: IconKey = .connect
    static let isRepeating: Bool = false

    var isLocked: Bool = false
    var selectedPaletteItem: String? = nil

    func paletteItems(in context: ToolContext) -> [PaletteItem] {
        let document = context.document
        let world = document.world

        var items: [PaletteItem] = []
        
        // TODO: Read from metamodel
        // TODO: Use connector glyphs and make the object palette single column and wide
        let connectableTypes = [
            StockFlowDomain.Types.Parameter,
            StockFlowDomain.Types.Flow
        ]

        for type in connectableTypes {
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

        return items
    }
    
    func makeInteraction(context: ToolContext) -> any ToolInteraction {
        return ConnectInteraction(document: context.document,
                                  canvas: context.canvas,
                                  selectedType: self.selectedPaletteItem)
    }
}

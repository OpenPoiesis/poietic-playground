//
//  SelectionTool.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 05/02/2026.
//

import CIimgui
import PoieticCore
import Diagramming

/// Selection tool is ...
///
class SelectionTool: CanvasTool {
    static let type: CanvasToolType = .selection
    static let iconKey: IconKey = .select
    static let isRepeating: Bool = true

    var isLocked: Bool = false
    var selectedPaletteItem: String? = nil

    // FIXME: THIS
    //    override func activate() {
//        createHandles()
//    }
//
//    override func deactivate() {
//        removeHandles()
//    }
//
    
    func makeInteraction(context: ToolContext) -> any ToolInteraction {
        return SelectionInteraction(context: context)
    }
}

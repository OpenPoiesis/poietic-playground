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
    override var type: CanvasToolType { .selection }
    override var iconKey: IconKey { .select }

    // FIXME: THIS
    //    override func activate() {
//        createHandles()
//    }
//
//    override func deactivate() {
//        removeHandles()
//    }
//
    
    override func makeInteraction(context: ToolContext) -> any ToolInteraction {
        // FIXME: Remove force unwrap, context MUST have document
        return SelectionInteraction(document: context.document!, canvas: context.canvas)
    }
}

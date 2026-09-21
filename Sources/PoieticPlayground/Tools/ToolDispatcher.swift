//
//  ToolManager.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 20/09/2026.
//




@MainActor
class ToolDispatcher {
    let tools: [CanvasTool]

    private(set) var activeTool: CanvasTool?
    private(set) var activeInteraction: any ToolInteraction?
    private(set) var engagedInteraction: (ToolInteraction, DiagramCanvas)?
    private(set) var previousTool: CanvasTool?
    
    var context: ToolContext?
    
    init() {
        let selectionTool = SelectionTool()
        let panTool = PanTool()
        self.tools = [
            selectionTool,
            PlacementTool(),
            ConnectTool(),
            panTool,
        ]
    }
    
    func select(_ toolType: CanvasToolType) {
        guard let tool: CanvasTool = tools.first(where: { $0.type == toolType} ),
              tool !== activeTool
        else { return }

        deactivate()
        previousTool = activeTool
        activeTool = tool
        activateCurrentTool()
    }
    
    func deactivate() {
        activeInteraction?.deactivate()
        activeInteraction = nil
//        capture = nil
    }
    
    func activateCurrentTool() {
        guard let context,
              let tool = activeTool
        else { return }
        
        let interaction = tool.makeInteraction(context: context)
        activeInteraction = interaction
        interaction.begin()
    }
    
}

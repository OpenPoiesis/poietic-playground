//
//  ToolManager.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 20/09/2026.
//

@MainActor
class ToolManager {
    let tools: [CanvasTool]
    private var navigation: NavigationInteraction?

    private(set) var activeTool: CanvasTool?
    private(set) var activeInteraction: any ToolInteraction?
    private(set) var capture: (interaction: ToolInteraction, canvas: DiagramCanvas)?
    private(set) var previousTool: CanvasTool?
    
    var context: ToolContext?
    
    var activePaletteItems: [PaletteItem] {
        guard let context,
              let activeTool
        else { return [] }
        
        return activeTool.paletteItems(in: context)
    }
    
    var selectedPaletteItem: String? {
        self.activeTool?.selectedPaletteItem
    }
    
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
    
    /// Bind to an editing context.
    ///
    func bind(workspace: any WorkspaceServices, document: Document, canvas: DiagramCanvas) {
        deactivate()
        context = ToolContext(workspace: workspace, document: document, canvas: canvas)
        navigation = nil // Force create new navigation in new canvas
        activateCurrentTool()
    }
    func unbind() {
        deactivate()
        context = nil
    }
    
    func isActive(_ tool: CanvasTool) -> Bool {
        tool === activeTool
    }
    
    /// Select tool of given type and activate it.
    ///
    func select(_ type: CanvasToolType) {
        guard let tool: CanvasTool = tools.first(where: { $0.type == type} ),
              tool !== activeTool
        else { return }

        deactivate()
        previousTool = activeTool
        activeTool = tool
        activateCurrentTool()
    }

    func activateCurrentTool() {
        guard let context,
              let tool = activeTool
        else { return }
        
        let interaction = tool.makeInteraction(context: context)
        activeInteraction = interaction
        interaction.begin()
        
        if navigation == nil {
            navigation = NavigationInteraction(canvas: context.canvas)
        }
    }

    func deactivate() {
        activeInteraction?.end()
        activeInteraction = nil
//        capture = nil
    }
    

    /// Select previous tool when current tool is `type`, otherwise select `type`.
    ///
    func toggle(_ type: CanvasToolType) {
        if activeTool?.type == type, let previousTool {
            select(previousTool.type)
        }
        else {
            select(type)
        }
    }
    
    @discardableResult
    func dispatch(_ event: ToolEvent, canvas: DiagramCanvas) -> EventDisposition {
        // FIXME: We are using capture here, but the interaction might be bound to other canvas on init (through tool's makeInteraction())
        if let capture, capture.canvas === canvas {
            let disposition = capture.interaction.handleEvent(event)
            switch disposition {
            case .ignored:
                break // navigation handles it
            case .handled:
                self.capture = nil
                return .handled
            case .engaged:
                return .engaged
            }
        }
        
        if let activeInteraction {
            let disposition = activeInteraction.handleEvent(event)
            switch disposition {
            case .ignored: break // navigation handles it
            case .handled: return .handled
            case .engaged: capture = (interaction: activeInteraction, canvas: canvas)
            }
        }
        
        return navigation?.handleEvent(event) ?? .ignored
    }
    
#if false
    func OLD_dispatch(_ event: ToolEvent) {
        var result: EventDisposition = .ignored
        var toolUsed: CanvasTool? = nil
        
        if let engagedTool = toolBar.engagedTool {
            result = engagedTool.handleEvent(event)
            toolUsed = engagedTool
        }
        else if let currentTool = toolBar.currentTool {
            result = currentTool.handleEvent(event)
            toolUsed = currentTool
            
            if result == .ignored,
               let fallbackTool = toolBar.secondaryTool
            {
                result = fallbackTool.handleEvent(event)
                toolUsed = fallbackTool
            }
        }
        
        switch result {
        case .engaged:
            toolBar.engagedTool = toolUsed
            
        case .handled, .ignored:
            toolBar.engagedTool = nil
        }
    }
#endif
    
    
}

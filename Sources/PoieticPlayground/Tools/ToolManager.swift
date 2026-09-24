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
    
    init() {
        let selectionTool = SelectionTool()
        let panTool = PanTool()
        self.tools = [
            selectionTool,
            PlacementTool(),
            ConnectTool(),
            panTool,
        ]
        self.activeTool = selectionTool
    }
    
    /// Bind to an editing context.
    ///
    func bind(workspace: any WorkspaceServices, document: Document, canvas: DiagramCanvas) {
        deactivate()
        context = ToolContext(workspace: workspace, document: document, canvas: canvas)
        navigation = NavigationInteraction(canvas: canvas)
        activateCurrentTool()
    }
    func unbind() {
        deactivate()
        context = nil
        navigation = nil
    }
    
    func isActive(_ tool: CanvasTool) -> Bool {
        tool === activeTool
    }
    
    func tool(type toolType: CanvasToolType) -> CanvasTool? {
        tools.first { type(of: $0).type == toolType }
    }
    
    /// Select tool of given type and activate it.
    ///
    func select(_ toolType: CanvasToolType) {
        guard let tool: CanvasTool = tool(type: toolType),
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
        
        if tool.selectedPaletteItem == nil, let first = tool.paletteItems(in: context).first {
            tool.selectedPaletteItem = first.identifier
        }
        let interaction = tool.makeInteraction(context: context)
        activeInteraction = interaction
        interaction.begin()
        
    }

    func releaseCapture() {
        guard let capture else { return }
        capture.interaction.end()
        self.capture = nil
    }
    
    func deactivate() {
        releaseCapture()
        activeInteraction?.end()
        activeInteraction = nil
    }
    

    /// Select previous tool when current tool is `type`, otherwise select `type`.
    ///
    func toggle(_ toolType: CanvasToolType) {
        if let activeTool,
           type(of: activeTool).type == toolType,
           let previousTool
        {
            select(type(of: previousTool).type)
        }
        else {
            select(toolType)
        }
    }
    
    /// Dispatches the tool event to an tool/grip interaction.
    ///
    /// The dispatch tries the following in given order:
    ///
    /// 1. Try captured interaction, and keep captured if still engaged.
    /// 2. If a grip was hit, then try to dispatch to an interaction that was made by active tool
    ///    for that grip. Capture the grip interaction.
    /// 3. Try active interaction, and keep captured if still engaged.
    /// 4. If none of the above handled or did engage, then try to forward to navigation.
    ///
    @discardableResult
    func dispatch(_ event: ToolEvent, canvas: DiagramCanvas) -> EventDisposition {
        var skip: Bool = false
        // FIXME: We are using capture here, but the interaction might be bound to other canvas on init (through tool's makeInteraction())
        if let capture, capture.canvas === canvas {
            let disposition = capture.interaction.handleEvent(event)
            switch disposition {
            case .ignored: skip = true
            case .handled: releaseCapture(); return .handled
            case .engaged: return .engaged
            }
        }
        else if let context,
                let tool = activeTool,
                event.type == .pointerDown,
                let target = canvas.hitGrip(screenPosition: event.screenPos),
                let interaction = tool.makeInteraction(grip: target, context: context)
        {
            interaction.begin()
            let disposition = interaction.handleEvent(event)

            switch disposition {
            case .ignored: break
            case .handled: releaseCapture(); return .handled
            case .engaged:
                capture = (interaction: interaction, canvas: canvas)
                return .engaged
            }
        }
        
        if !skip, let activeInteraction {
            let disposition = activeInteraction.handleEvent(event)
            switch disposition {
            case .ignored: break // navigation handles it
            case .handled: return .handled
            case .engaged:
                capture = (interaction: activeInteraction, canvas: canvas)
                return .engaged
            }
        }
        
        return navigation?.handleEvent(event) ?? .ignored
    }

    var selectedPaletteItem: String? {
        self.activeTool?.selectedPaletteItem
    }
    
    func selectPaletteItem(_ identifier: String) {
        guard let tool = activeTool,
              tool.selectedPaletteItem != identifier
        else { return }
        tool.selectedPaletteItem = identifier
        deactivate()
        activateCurrentTool()
    }
    
}

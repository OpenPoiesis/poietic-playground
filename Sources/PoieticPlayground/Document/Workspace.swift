//
//  Workspace.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 14/09/2026.
//

import PoieticCore

@MainActor
protocol DocumentBound {
    func bind(_ document: Document)
    func unbind()
}


// Group information that we want to request from the app.
// TODO: This is just a placeholder during refactoring
struct _PLACEHOLDER_AppContext {
    let isInteractionBlocked: Bool
    func queueAlert(title: String, message: String) { }
}

@MainActor
class Workspace {
    // TODO: Add multi-document support later
    private(set) var currentDocument: Document?
    private var bound: [any DocumentBound] = []

    struct QueuedCommand {
        let command: WorkspaceCommand
        weak let document: Document?
        weak let canvas: DiagramCanvas?
    }
    var appContext: _PLACEHOLDER_AppContext? = nil

    var commandQueue: [QueuedCommand]
    
    // TODO: Rename to activeCanvas, make optional. today we have just one, but window split is planned
    var canvas: DiagramCanvas
    var player: ResultPlayer

    let toolBar: ToolBar
    
    var panels: [any Panel] = []
    var editors: InlineEditorManager

    let controlBar: ControlBar
    let dashboard: Dashboard
    let issuesPanel: IssuesPanel
    let graphicFunctionPanel: GraphicalFunctionPanel
    let dataTablePanel: DataTablePanel
    let inspector: InspectorPanel
    let debugDesignPanel: DebugDesignPanel
    let metamodelPanel: MetamodelPanel
    

    // let bound object list
    // let deferred action queue
    // func new/open/save/close/unsaved changes review
    
    var currentTool: CanvasTool? { toolBar.currentTool }


    init() {
        self.currentDocument = nil
        self.commandQueue = []
        self.bound = []

        self.canvas = DiagramCanvas()
        bound.append(self.canvas)
        self.player = ResultPlayer()
        bound.append(self.player)
        self.toolBar = ToolBar()
        bound.append(self.toolBar)

        panels = []
        self.inspector = InspectorPanel()
        panels.append(self.inspector)
        bound.append(self.inspector)
        self.controlBar = ControlBar()
        panels.append(self.controlBar)
        self.issuesPanel = IssuesPanel()
        bound.append(self.issuesPanel)
        panels.append(self.issuesPanel)
        self.dashboard = Dashboard()
        bound.append(self.dashboard)
        panels.append(self.dashboard)
        self.graphicFunctionPanel = GraphicalFunctionPanel()
        bound.append(self.graphicFunctionPanel)
        panels.append(self.graphicFunctionPanel)
        self.debugDesignPanel = DebugDesignPanel()
        bound.append(self.debugDesignPanel)
        panels.append(self.debugDesignPanel)
        self.dataTablePanel = DataTablePanel()
        bound.append(self.dataTablePanel)
        panels.append(self.dataTablePanel)
        self.metamodelPanel = MetamodelPanel()
        bound.append(self.metamodelPanel)
        panels.append(self.metamodelPanel)

        self.controlBar.bind(player)

        
        // Register inline editors
        editors = InlineEditorManager()
        self.editors.register(name: "name", editor: NameInlineEditor())
        self.editors.register(name: "formula", editor: FormulaInlineEditor())
        self.editors.register(name: "delay",
                                    editor: NumericValueInlineEditor(attribute: "delay_duration", iconKey: .timeWindow))
        self.editors.register(name: "smooth",
                                    editor: NumericValueInlineEditor(attribute: "window_time", iconKey: .timeWindow))
        self.editors.register(name: "graphical_function",
                                    editor: GraphicalFunctionInlineEditor(panel: graphicFunctionPanel))
        canvas.editorManager = editors
    }
    
    func update(_ timeDelta: Double) {
        updateDocument(timeDelta)

        if player.isRunning {
            player.update(timeDelta)
        }

        // Update UI components
        canvas.update(timeDelta)
        toolBar.update(timeDelta)
        for panel in panels {
            panel.update(timeDelta)
        }
        
        currentDocument?.run(schedule: DocumentCleanupSchedule.self)
    }
    
    func draw() {
        canvas.draw()
        toolBar.draw()
        for panel in panels {
            guard panel.isVisible else { continue }
            panel.draw()
        }
    }

    func dispatchInput(_ input: InputFrame, gestures: [GestureEvent]) {
        let gestureEvents = gestures.map { ToolEvent($0, input: input) }

        let events = canvas.recognizeInput(input) + gestureEvents

        for event in events {
            dispatchToolEvent(event)
        }
    }

    func dispatchToolEvent(_ event: ToolEvent) {
        var result: CanvasTool.EngagementResult = .pass
        var toolUsed: CanvasTool? = nil
        
        if let engagedTool = toolBar.engagedTool {
            result = engagedTool.handleEvent(event)
            toolUsed = engagedTool
        }
        else if let currentTool = toolBar.currentTool {
            result = currentTool.handleEvent(event)
            toolUsed = currentTool
            
            if result == .pass,
               let fallbackTool = toolBar.secondaryTool
            {
                result = fallbackTool.handleEvent(event)
                toolUsed = fallbackTool
            }
        }
        
        switch result {
        case .engaged:
            toolBar.engagedTool = toolUsed
            
        case .consumed, .pass:
            toolBar.engagedTool = nil
        }

    }
    

    func updateDocument(_ timeDelta: Double) {
        guard let appContext else { return }
        guard !appContext.isInteractionBlocked else { return }
        // Run the Command Queue.
        // When a command replaces the document, we continue with the new one.
        // The rest of the commands in the replaced document queue is dropped.
        while !commandQueue.isEmpty {
            let item = commandQueue.removeFirst()
            let command = item.command
            guard let document = item.document else { continue }
            self.runCommand(command, document: document, canvas: item.canvas)
        }
        
        if let document = self.currentDocument {
            do {
                try document.consumeAndAcceptTransaction()
            }
            catch {
                // This is not user's fault and never should be.
                // The application failed to make sure structural integrity is assured
                appContext.queueAlert(title: "Plane validation error (report to developers)",
                                      message: String(describing: error))
                return
            }
            document.update(timeDelta)
        }
    }

    func replaceDocument(_ newDocument: Document) {
        for object in bound {
            object.unbind()
        }
        // modals.removeAll(scope: .document)
        // flows.discardAll()
        // old.flushOpenTransaction()
        
        currentDocument = newDocument
        for object in bound {
            object.bind(newDocument)
        }

        canvas.setView(offset: .zero, zoom: 1)
        connectObservers(to: newDocument)
    }
    
    func connectObservers(to document: Document) {
        document.addObserver(inspector.onSelectionChanged, on: .designPlaneChanged)
        document.addObserver(inspector.onSelectionChanged, on: .selectionChanged)
        document.addObserver(inspector.onSimulationFinished, on: .simulationFinished)
        document.addObserver(canvas.onDesignPlaneChanged, on: .designPlaneChanged)
        document.addObserver(canvas.onSelectionChanged, on: .selectionChanged)
        document.addObserver(canvas.onSimulationPlayerStep, on: .simulationPlayerStep)
        document.addObserver(canvas.onSimulationPlayerStep, on: .simulationFinished)

        document.addObserver(canvas.onInteractivePreviewChanged, on: .previewChanged)
        document.addObserver(canvas.onPreviewStarted, on: .previewStarted)
        document.addObserver(canvas.onPreviewEnded, on: .previewEnded)

        document.addObserver(controlBar.onDesignPlaneChanged, on: .designPlaneChanged)
        document.addObserver(controlBar.onSimulationPlayerStep, on: .simulationPlayerStep)
        document.addObserver(player.onDesignPlaneChanged, on: .designPlaneChanged)
        document.addObserver(player.onSimulationFailed, on: .simulationFailed)
        document.addObserver(dashboard.onDesignPlaneChanged, on: .designPlaneChanged)

        document.addObserver(graphicFunctionPanel.onSelectionChanged, on: .selectionChanged)

        document.addObserver(debugDesignPanel.onSelectionChanged, on: .selectionChanged)
    }


}


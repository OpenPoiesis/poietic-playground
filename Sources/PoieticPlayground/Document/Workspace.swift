//
//  Workspace.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 14/09/2026.
//

import PoieticCore
import Diagramming

@MainActor
protocol DocumentBound {
    func bind(_ document: Document)
    func unbind()
}

@MainActor
protocol WorkspaceBound {
    func bind(workspace: any WorkspaceServices, document: Document)
    func unbind()
}



@MainActor
protocol Reporter: AnyObject {
    func log(_ text: String)
    func logError(_ text: String)
    func report(title: String, message: String, style: MessageStyle)
}

// Group information that we want to request from the app.
// TODO: This is just a placeholder during refactoring
@MainActor
protocol ApplicationEnvironment: Reporter {
    func setPasteboardText(_ text: String) -> Bool
    func getPasteboardText() -> String?

    var isInteractionBlocked: Bool { get }

    func presentDecision(title: String, message: String, choices: [DecisionFlowChoice])
    func presentFileSelector(title: String, mode: FileSelectionMode, filter: String?,
                             completion: @escaping (String?) -> Void)
    func startSubflow(_ flow: any DecisionFlow, completion: @escaping (DecisionFlowOutcome) -> Void)
    func finish(_ flow: any DecisionFlow, outcome: DecisionFlowOutcome)
    func requestQuit()
}

@MainActor
class Workspace {
    // TODO: Add multi-document support later
    private(set) var currentDocument: Document?
    private var bound: [any DocumentBound] = []
    private var workspaceBound: [any WorkspaceBound] = []

    weak var environment: any ApplicationEnvironment? = nil

    var notation: Notation
    
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


    init(environment: ApplicationEnvironment, notation: Notation) {
        self.environment = environment
        self.notation = notation
        
        self.currentDocument = nil

        self.bound = []

        self.canvas = DiagramCanvas()
        bound.append(self.canvas)
        self.player = ResultPlayer()
        bound.append(self.player)

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

        self.toolBar = ToolBar()
        
        // FIXME: Use enum instead of names
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

        self.toolBar.bind(self)
    }
    
    /// Update the document and the world.
    ///
    /// The flow:
    ///
    /// 1. Updates the document ``updateDocument(_:)``
    /// 2. Checks whether the player is running and updates the player.
    /// 3. If the player requests world update, then runs ``PlayerStepSchedule``
    ///    through ``Document/updatePlayerStep(step:time:)``.
    /// 4. Updates canvas.
    /// 5. Updates toolbar.
    /// 6. Updates all workspace-associated panels.
    /// 7. Finalises by running the `DocumentCleanupSchedule`.
    ///
    func update(_ timeDelta: Double) {
        updateDocument(timeDelta)

        if player.isRunning {
            player.update(timeDelta)
        }
        if player.needsWorldUpdate {
            do {
                try currentDocument?.updatePlayerStep(step: player.currentStep,
                                                      time: player.currentTime)
            }
            catch {
                environment?.report(title: "Player Schedule Failed",
                                    message: "Please file an issue with developers",
                                    style: .error)

            }
            player.worldUpdated()
        }

        // Update UI components
        canvas.update(timeDelta)
        toolBar.update(timeDelta)
        for panel in panels {
            panel.update(timeDelta)
        }
        
        do {
            try currentDocument?.world.run(schedule: DocumentCleanupSchedule.self)
        }
        catch {
            environment?.report(title: "Internal System Error", message: String(describing: error), style: .error)
            environment?.logError("Internal system error:" + String(describing: error))
        }
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
        let events: [ToolEvent]
        
        if canvas.isPointerOver {
            let gestureEvents = gestures.map { ToolEvent($0, input: input) }
            events = canvas.recognizeInput(input) + gestureEvents
        }
        else {
            events = canvas.recognizeInput(input)
        }


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

    /// Updates the document.
    ///
    /// Called by ``update(_:)`` and runs only when interaction is not blocked.
    ///
    /// The flow:
    ///
    /// 1. Runs commands in the document queue (``Document/commandQueue``).
    ///    See ``executeWithReporting(_:document:canvas:)``.
    /// 2. Tries to accept the transaction ``Document/consumeAndAcceptTransaction()``
    /// 3. Updates the document ``Document/update(_:)`` which does the following:
    ///     - changes world plane if needed, and then simulate
    ///     - runs `DocumentUpdateSchedule`.
    ///     - runs `InteractivePreviewSchedule` if interactive preview is active.
    ///
    func updateDocument(_ timeDelta: Double) {
        guard let environment,
              let document = currentDocument
        else { return }
        guard !environment.isInteractionBlocked else { return }
        
        while !document.commandQueue.isEmpty {
            let invocation = document.commandQueue.removeFirst()
            executeWithReporting(invocation.command,
                                 document: document,
                                 canvas: invocation.canvas)
        }
        
        do {
            try document.consumeAndAcceptTransaction()
            environment.log("Transaction accepted. Current plane: \(document.design.currentPlaneID!), plane count: \(document.design.planes.count)")
        }
        catch {
            // This is not user's fault and never should be.
            // The application failed to make sure structural integrity is assured
            environment.report(title: "Plane validation error (report to developers)",
                               message: String(describing: error),
                               style: .error)
            return
        }

        do {
            try document.update(timeDelta)
        }
        catch {
            environment.report(title: "Internal System Error", message: String(describing: error), style: .error)
            environment.logError("Internal system error during document update:" + String(describing: error))
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
        document.addObserver(player.onSimulationFinished, on: .simulationFinished)
        document.addObserver(player.onSimulationFailed, on: .simulationFailed)

        document.addObserver(dashboard.onDesignPlaneChanged, on: .designPlaneChanged)

        document.addObserver(graphicFunctionPanel.onSelectionChanged, on: .selectionChanged)

        document.addObserver(debugDesignPanel.onSelectionChanged, on: .selectionChanged)
    }


}


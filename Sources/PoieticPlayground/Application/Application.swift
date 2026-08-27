//
//  Application.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 26/01/2026.
//

import PoieticCore
import PoieticFlows
import CIimgui
import Csdl3
import Diagramming
import Foundation

/// Main orchestrator
///
/// Responsibilities:
///
/// - Lifecycle and main loop orchestration
/// - UI panel ownership and binding orchestration
/// - Input routing (shortcuts → actions → commands)
/// - Resource management
/// - Glue between Document and UI
@MainActor
class Application {
    // TODO: Temporary for prototyping
    static var shared: Application {
        guard let app = self._shared else { fatalError("Shared application is not set-up") }
        return app
    }
    internal static var _shared: Application? = nil
    
    // Dumping ground of globals (for now)
    //    static let NewDesignTemplatePath = "designs/new_canvas.json"
    static let NewDesignTemplatePath = "designs/design-capital.poietic"
    static let DefaultStockFlowPictogramsPath = "stock_flow_pictograms.json"
    static let MainWindowName = "Poietic Playground"
    static let DefaultWindowWidth = 1280
    static let DefaultWindowHeight = 800
    static let PictogramAdjustmentScale = 0.5
    
    var showMetrics = false
    var debugCanvasRendering = false
    var quitRequested: Bool = false
    
    var pendingToolEvents: [ToolEvent] = []
    
    // -- Document --
    var canvas: DiagramCanvas
    var player: ResultPlayer

    // -- Views and Controller-likes --
    let filePicker: FilePickerPanel
    let inspector: InspectorPanel
    var alertPanel: AlertPanel
    let aboutPanel: AboutPanel
    let settingsPanel: SettingsPanel
    // Document Content Panels
    let issuesPanel: IssuesPanel
    let graphicFunctionPanel: GraphicalFunctionPanel
    let dataTablePanel: DataTablePanel
    
    // Help Panels
    let metamodelPanel: MetamodelPanel
    let keyboardShortcutsPanel: KeyboardShortcutsPanel
    let debugDesignPanel: DebugDesignPanel
    
    var panels: [any Panel] = []
    
    var canvasTools: [CanvasTool]
    var currentTool: CanvasTool? { toolBar.currentTool }
    let toolBar: ToolBar
    let controlBar: ControlBar
    let dashboard: Dashboard
    
    // Inline Editors
    var editorManager: InlineEditorManager

    // ## GUI
    //
    // ## The Document – Design and World
    var document: Document?
    var notation: Notation
    
    init() {
        self.notation = Notation.DefaultNotation
        
        // Document
        self.document = nil
        self.player = ResultPlayer()
        
        // User Interface
        self.canvas = DiagramCanvas()

        // Special panels
        self.toolBar = ToolBar()
        self.alertPanel = AlertPanel()
        self.filePicker = FilePickerPanel()

        // Regualr Panels
        panels = []
        self.inspector = InspectorPanel()
        panels.append(self.inspector)
        self.aboutPanel = AboutPanel()
        panels.append(self.aboutPanel)
        self.controlBar = ControlBar()
        panels.append(self.controlBar)
        self.settingsPanel = SettingsPanel()
        panels.append(self.settingsPanel)
        self.issuesPanel = IssuesPanel()
        panels.append(self.issuesPanel)
        self.dashboard = Dashboard()
        panels.append(self.dashboard)
        self.keyboardShortcutsPanel = KeyboardShortcutsPanel()
        panels.append(self.keyboardShortcutsPanel)
        self.graphicFunctionPanel = GraphicalFunctionPanel()
        panels.append(self.graphicFunctionPanel)
        self.metamodelPanel = MetamodelPanel()
        panels.append(self.metamodelPanel)

        self.debugDesignPanel = DebugDesignPanel()
        panels.append(self.debugDesignPanel)

        self.dataTablePanel = DataTablePanel()
        panels.append(self.dataTablePanel)
        
        self.canvasTools = [
            SelectionTool(),
            PlacementTool(),
            ConnectTool(),
            PanTool(),
        ]
        
        // Register inline editors
        editorManager = InlineEditorManager()
        self.editorManager.register(name: "name", editor: NameInlineEditor())
        self.editorManager.register(name: "formula", editor: FormulaInlineEditor())
        self.editorManager.register(name: "delay",
                                    editor: NumericValueInlineEditor(attribute: "delay_duration", iconKey: .timeWindow))
        self.editorManager.register(name: "smooth",
                                    editor: NumericValueInlineEditor(attribute: "window_time", iconKey: .timeWindow))
        self.editorManager.register(name: "graphical_function",
                                    editor: GraphicalFunctionInlineEditor(panel: graphicFunctionPanel))
        canvas.editorManager = editorManager
        
        Self._shared = self
    }
   
    
    func applicationSessionDebugWindow() {
        ImGui.Begin("Application Session")
        ImGui.TextUnformatted("Current tool: \(toolBar.currentTool?.name, default: "no tool")")
        if let document {
            let plane = document.world.plane
            let wPlaneLabel: String = plane.map { String(describing: $0.id) } ?? "(no plane)"
            let cPlaneLabel: String = document.design.currentPlane.map { String(describing: $0.id) } ?? "(no plane)"
            ImGui.TextUnformatted("Design plane: \(cPlaneLabel)")
            ImGui.TextUnformatted("World plane: \(wPlaneLabel)")
            ImGui.TextUnformatted("Has Transaction: \(document.hasTransaction)")
            ImGui.TextUnformatted("Selection count: \(document.selection.count)")
        }
        ImGui.End()
    }
    
    func alert(title: String, message: String) {
        self.alertPanel.title = title
        self.alertPanel.message = message
        self.alertPanel.isVisible = true
    }
    
    // FIXME: Make a proper alert mechanism. This is a quick hack to silence the compiler after refactoring. (see callers of this)
    func queueAlert(title: String, message: String) async {
        alert(title: title, message: message)
    }

    func log(_ message: String) {
        print("INFO: ", message)
    }
    func logError(_ message: String) {
        print("ERROR: ", message)
    }
}

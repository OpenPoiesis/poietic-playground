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
   
    var pendingBackendGestures: [GestureEvent] = []
    
    var showMetrics = false
    var debugCanvasRendering = false
    var quitRequested: Bool = false
    
    // -- Document --

    // -- Modals and Decisions --
    var isInteractionBlocked: Bool {
        modalQueue.contains { $0.status != .resolved } || decisionManager.isActive
    }
    var modalQueue: [any ModalDialog] = []
    var activeModal: (any ModalDialog)? {
        modalQueue.first { $0.status == .active}
    }
    var lastFilePickerDirectory = "."
    var decisionManager: DecisionFlowManager = DecisionFlowManager()
    
    // -- Views and Controller-likes --
    let aboutPanel: AboutPanel
    let settingsPanel: SettingsPanel
    
    // Help Panels
    let metamodelPanel: MetamodelPanel
    let keyboardShortcutsPanel: KeyboardShortcutsPanel
    
    var panels: [any Panel] = []
    

    // ## GUI
    //
    // ## The Document – Design and World
    var workspace: Workspace?
    var notation: Notation
    
    var currentDocument: Document? { workspace?.currentDocument }
    
    init() {
        self.notation = Notation.DefaultNotation
        
        // Document
        self.workspace = nil

        // Regualr Panels
        panels = []
        self.aboutPanel = AboutPanel()
        panels.append(self.aboutPanel)
        self.settingsPanel = SettingsPanel()
        panels.append(self.settingsPanel)
        self.keyboardShortcutsPanel = KeyboardShortcutsPanel()
        panels.append(self.keyboardShortcutsPanel)
        self.metamodelPanel = MetamodelPanel()
        panels.append(self.metamodelPanel)
        
        Self._shared = self
    }

    func requestQuit() {
        self.quitRequested = true
    }
    
    func queueAlert(title: String, message: String) {
        let alert = ConfirmationDialog(
            title: title,
            message: message,
            options: [
                DecisionOption("Dismiss")
            ]
        )
        
        queueDialog(alert)
    }
    

    func log(_ message: String) {
        print("INFO: ", message)
    }
    func logError(_ message: String) {
        print("ERROR: ", message)
    }
}

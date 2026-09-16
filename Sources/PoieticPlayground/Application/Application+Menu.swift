//
//  Application+mainMenu.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 28/01/2026.
//
import Foundation
import CIimgui

struct KeyModifier: OptionSet {
    let rawValue: UInt8
    static let cmd: KeyModifier = KeyModifier(rawValue: 1 << 0)
    static let shift: KeyModifier = KeyModifier(rawValue: 1 << 1)
    static let alt: KeyModifier = KeyModifier(rawValue: 1 << 2)
}
struct Menu {
    let label: String
    let items: [MenuItem]
}

struct MenuItem {
    let label: String
    let key: ImGuiKey
//    let modifier: KeyModifier
    let action: (() -> Void)
    
    init(_ label: String, key: ImGuiKey = ImGuiKey_None, action: @escaping (() -> Void)) {
        self.label = label
        self.key = key
        self.action = action
    }
}

extension Application {
    func mainMenu() {
        // In your main rendering loop, typically after ImGui.NewFrame()
        if ImGui.BeginMainMenuBar() {
            
            if ImGui.BeginMenu("Playground") {
                if ImGui.MenuItem("About", nil) {
                    aboutPanel.isVisible = true
                }
                if ImGui.MenuItem("Settings", "Cmd+,", &settingsPanel.isVisible) {
                    // Nothing
                }
                ImGui.Separator()
                if ImGui.MenuItem("Quit", "Cmd+Q") {
                    handleAction(.quit)
                }
                ImGui.EndMenu()
            }
            // File menu
            if ImGui.BeginMenu("Design") {
                if ImGui.MenuItem("New", "Cmd+N") {
                    handleAction(.new)
                }
                if ImGui.MenuItem("Open", "Cmd+O") {
                    handleAction(.open)
                }
                
                ImGui.Separator()
                
                if ImGui.MenuItem("Save", "Cmd+S") {
                    handleAction(.save)
                }
                if ImGui.MenuItem("Save As...", "Cmd+Shift+S") {
                    handleAction(.saveAs)
                }
                
                ImGui.Separator()

                if ImGui.MenuItem("Export SVG...", "Cmd+Shift+E") {
                    handleAction(.exportSVG)
                }

                
                ImGui.EndMenu()
            }
            
            // Edit menu
            if ImGui.BeginMenu("Edit") {
                if ImGui.MenuItem("Undo", "Cmd+Z", false, canUndo()) {
                    handleAction(.undo)
                }
                if ImGui.MenuItem("Redo", "Cmd+Y", false, canRedo()) {
                    handleAction(.redo)
                }
                
                ImGui.Separator()
                
                if ImGui.MenuItem("Cut", "Cmd+X", false, hasSelection()) {
                    handleAction(.cut)
                }
                if ImGui.MenuItem("Copy", "Cmd+C", false, hasSelection()) {
                    handleAction(.copy)
                }
                if ImGui.MenuItem("Paste", "Cmd+V") {
                    handleAction(.paste)
                }
                if ImGui.MenuItem("Delete", "Delete") {
                    handleAction(.delete)
                }
                ImGui.Separator()
                if ImGui.MenuItem("Select All", "Cmd+A") {
                    handleAction(.selectAll)
                }

               ImGui.EndMenu()
            }
            
            // View menu
            if ImGui.BeginMenu("View") {
                // TODO: Implement value indicators toggle
//                if ImGui.MenuItem("Show Value Indicators", nil, &canvas.showValueIndicators) {
//                }

                var inspectorVisible = workspace?.inspector.isVisible ?? false
                if ImGui.MenuItem("Show Inspector", "Cmd+I", &inspectorVisible) {
                    handleAction(.toggleInspector)
                }

                var issuesPanelVisible = workspace?.issuesPanel.isVisible ?? false
                if ImGui.MenuItem("Show Issues", nil, &issuesPanelVisible) {
                    handleAction(.toggleInspector)
                }
                
                var dataTablePanelVisible = workspace?.dataTablePanel.isVisible ?? false
                if ImGui.MenuItem("Show Data Table", nil, &dataTablePanelVisible) {
                    handleAction(.toggleDataTablePanel)
                }
                var gfPanelVisible = workspace?.graphicFunctionPanel.isVisible ?? false
                if ImGui.MenuItem("Show Graphical Function Panel", nil, &gfPanelVisible) {
                    handleAction(.toggleGraphicalFunctionPanel)
                }
                var toolBarVisible = workspace?.toolBar.isVisible ?? false
                ImGui.Separator()
                if ImGui.MenuItem("Show Toolbar", nil, &toolBarVisible) {
                    handleAction(.toggleToolBar)
                }
                ImGui.Separator()
                if ImGui.MenuItem("Show Metrics", nil, &showMetrics) {
                    ImGui.ShowMetricsWindow()
                }

                ImGui.EndMenu()
            }
            // Model menu
            if ImGui.BeginMenu("Model") {
                if ImGui.MenuItem("Auto-connect Parameters", nil) {
                    handleAction(.autoConnectParameters)
                }
                ImGui.EndMenu()
            }
            // Window menu (for window management)
            if ImGui.BeginMenu("Simulation") {
                if let player = workspace?.player {
                    if ImGui.MenuItem(player.isRunning ? "Stop" : "Play") {
                        if player.isRunning { handleAction(.stopPlayer) }
                        else                { handleAction(.runPlayer) }
                    }
                }

                ImGui.EndMenu()
            }

            if ImGui.BeginMenu("Debug") {
                var ddPanelVisible = workspace?.debugDesignPanel.isVisible ?? false
                if ImGui.MenuItem("Objects Panel", nil, &ddPanelVisible) {
                    handleAction(.toggleDebugDesignPanel)
                }
                if ImGui.MenuItem("Debug Diagram Canvas Rendering", nil, &debugCanvasRendering) {
                    self.workspace?.canvas.debugRendering = self.debugCanvasRendering
                    self.workspace?.canvas.overlays.setAllNeedsRender()
                }
                ImGui.EndMenu()
            }

            // Help menu
            if ImGui.BeginMenu("Help") {
                if ImGui.MenuItem("Keyboard Shortcuts") {
                    self.keyboardShortcutsPanel.isVisible = true
                }
                if ImGui.MenuItem("Metamodel Documentation") {
                    self.metamodelPanel.isVisible = true
                }
                ImGui.EndMenu()
            }
            
            ImGui.EndMainMenuBar()
        }
    }
    
    func canUndo() -> Bool { currentDocument?.design.canUndo ?? false }
    func canRedo() -> Bool { currentDocument?.design.canRedo ?? false }
    func hasSelection() -> Bool { (currentDocument?.selection).map { !$0.isEmpty } ?? false }

}

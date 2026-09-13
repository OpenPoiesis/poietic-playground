//
//  App+input.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 28/01/2026.
//
import CIimgui
import Foundation
import PoieticCore

struct ActionShortcut {
    let action: Action
    let key: ImGuiKeyChord
    let flags: ImGuiInputFlags

    init(_ action: Action, key: ImGuiKey, flags: ImGuiInputFlags = 0) {
        self.init(action, key: ImGuiKeyChord(key.rawValue), flags: flags)
    }
    
    init(_ action: Action, key: ImGuiKeyChord, flags: ImGuiInputFlags = 0) {
        self.action = action
        self.key = key
        self.flags = ImGuiInputFlags(flags | Int32(ImGuiInputFlags_RouteGlobal.rawValue))
    }
    
    var keyLabel: String {
        let io = ImGui.GetIO().pointee
        
        let justKey = key & ~ImGuiMod_Mask_.rawValue
        let name: String
        if let ptr = ImGui.GetKeyName(ImGuiKey(rawValue: justKey)) {
            name = String(cString: ptr)
        }
        else {
            name = ""
        }
        var modName: String = ""
        if key & ImGuiMod_Ctrl.rawValue != 0 {
            modName += io.ConfigMacOSXBehaviors ? "Cmd+" : "Ctrl+"
        }
        if key & ImGuiMod_Shift.rawValue != 0 {
            modName += "Shift+"
        }
        if key & ImGuiMod_Alt.rawValue != 0 {
            modName += "Alt+"
        }
        if key & ImGuiMod_Super.rawValue != 0 {
            modName += io.ConfigMacOSXBehaviors ? "Ctrl+" : "Super+"
        }
        
        return modName + name
    }
}

let GlobalShortcuts: [ActionShortcut] = [
    // Application
    ActionShortcut(.settings, key: ImGuiMod_Ctrl | ImGuiKey_Comma),

    // Edit
    ActionShortcut(.undo, key: ImGuiMod_Ctrl | ImGuiKey_Z),
    ActionShortcut(.redo, key: ImGuiMod_Ctrl | ImGuiMod_Shift | ImGuiKey_Z),

    ActionShortcut(.cut, key: ImGuiMod_Ctrl | ImGuiKey_X),
    ActionShortcut(.copy, key: ImGuiMod_Ctrl | ImGuiKey_C),
    ActionShortcut(.paste, key: ImGuiMod_Ctrl | ImGuiKey_V),
    ActionShortcut(.delete, key: ImGuiKey_Backspace),

    ActionShortcut(.selectAll, key: ImGuiMod_Ctrl | ImGuiKey_A),

    // File
    ActionShortcut(.new, key: ImGuiMod_Ctrl | ImGuiKey_N),
    ActionShortcut(.open, key: ImGuiMod_Ctrl | ImGuiKey_O),
    ActionShortcut(.save, key: ImGuiMod_Ctrl | ImGuiKey_S),
    ActionShortcut(.saveAs, key: ImGuiMod_Ctrl | ImGuiMod_Shift | ImGuiKey_S),
    
    // View
    ActionShortcut(.toggleInspector, key: ImGuiMod_Ctrl | ImGuiKey_I),
    ActionShortcut(.toggleIssuesPanel, key: ImGuiMod_Ctrl | ImGuiKey_5),
    ActionShortcut(.resetZoom, key: ImGuiMod_Ctrl | ImGuiKey_0),

    // Tools
    ActionShortcut(.switchSelectionTool, key: ImGuiKey_1),
    ActionShortcut(.switchPlacementTool, key: ImGuiKey_2),
    ActionShortcut(.switchConnectTool, key: ImGuiKey_3),
    ActionShortcut(.switchPanTool, key: ImGuiKey_Space),
    
    // Inspector
    ActionShortcut(.overviewInspector, key: ImGuiMod_Ctrl | ImGuiKey_1),
    ActionShortcut(.propertiesInspector, key: ImGuiMod_Ctrl | ImGuiKey_2),

    // Inline Editors
    ActionShortcut(.nameInlineEditor, key: ImGuiKey_Enter),
    ActionShortcut(.secondaryInlineEditor, key: ImGuiKey_Equal),
]


extension Application {
    func globalShortcutAction() -> Action? {
        for shortcut in GlobalShortcuts {
            if ImGui.Shortcut(shortcut.key, shortcut.flags) {
                return shortcut.action
            }
        }
        return nil
    }
    
    func handleAction(_ action: Action) {
        switch action {
        // -- Tools --
        case .switchSelectionTool: toolBar.setTool("selection")
        case .switchPlacementTool: toolBar.setTool("placement")
        case .switchConnectTool: toolBar.setTool("connect")
        case .switchPanTool:
            if let previousTool = toolBar.previousTool,
               toolBar.currentTool is PanTool
            {
                toolBar.setTool(previousTool)
            }
            else {
                toolBar.setTool("pan")
            }
            
        // -- Application --
        case .settings: self.openSettings()
        case .quit:
            self.startFlow(QuitApplicationFlow(context: self))
            
        // -- File --
        case .new:       self.startFlow(NewDesignFlow(context: self))
        case .open:      self.startFlow(OpenDocumentWithFileSelectionFlow(context: self))
        case .save:      self.startFlow(SaveDocumentFlow(context: self))
        case .saveAs:    self.startFlow(SaveDocumentWithFileSelectionFlow(context: self))
        case .exportSVG: self.startFlow(ExportSVGFlow(context: self))
            
        // -- Edit --
        case .cut:
            guard let document else { break }
            let ids: [ObjectID] = Array(document.selection.ids)
            document.queueCommand(CutToPasteboardCommand(ids))
        case .copy:
            guard let document else { break }
            let ids: [ObjectID] = Array(document.selection.ids)
            document.queueCommand(CopyToPasteboardCommand(ids))
        case .delete:
            guard let document else { break }
            let ids: [ObjectID] = Array(document.selection.ids)
            document.queueCommand(DeleteObjectsCommand(ids))
        case .paste:
            document?.queueCommand(PasteFromPasteboardCommand())
            
        case .undo: document?.queueCommand(UndoCommand())
        case .redo: document?.queueCommand(RedoCommand())
        case .selectAll:
            self.selectAll()
            
        // -- View ---
        case .toggleInspector:   self.inspector.isVisible = !self.inspector.isVisible
        case .toggleIssuesPanel: self.issuesPanel.isVisible = !self.issuesPanel.isVisible
        case .resetZoom:         document?.queueCommand(ResetZoomCommand())
            
        // -- Inspector --
        case .overviewInspector:
            self.inspector.selectTab(.overview)
            self.inspector.isVisible = true
        case .propertiesInspector:
            self.inspector.selectTab(.properties)
            self.inspector.isVisible = true
            
        case .nameInlineEditor:      self.canvas.openInlineEditorForSelection("name")
        case .secondaryInlineEditor: self.canvas.openSecondaryInlineEditorForSelection()
        }
    }
}

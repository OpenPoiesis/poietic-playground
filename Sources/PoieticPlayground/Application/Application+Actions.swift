//
//  App+input.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 28/01/2026.
//
import CIimgui
import Foundation
import PoieticCore



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
        // Allow workspace to handle action first.
        if let workspace, workspace.handleAction(action) { return }
        
        switch action {
        case .settings:
            self.openSettings()
        case .quit:
            self.startFlow(QuitApplicationFlow(context: flowContext()))
            
        // -- File --
        case .new:
            self.startFlow(NewDesignFlow(context: flowContext()))
        case .open:
            self.startFlow(OpenDocumentWithFileSelectionFlow(context: flowContext()))
        case .save:
            guard let document = workspace?.currentDocument else { break }
            self.startFlow(SaveDocumentFlow(context: flowContext(), document: document))
        case .saveAs:
            guard let document = workspace?.currentDocument else { break }
            self.startFlow(SaveDocumentWithFileSelectionFlow(context: flowContext(), document: document))
        case .exportSVG:
            guard let document = workspace?.currentDocument else { break }
            self.startFlow(ExportSVGFlow(context: flowContext(), document: document))

        default:
            self.log("Unhandled action: \(action.name)")
        }
    }
    
    func openSettings() {
        settingsPanel.isVisible = true
    }

    func setInterfaceColorScheme(_ scheme: InterfaceStyle.ColorScheme) {
        guard scheme != InterfaceStyle.current.scheme else { return }
        let style = InterfaceStyle(scheme: scheme)
        InterfaceStyle.current = style
        
        switch scheme {
        case .light: ImGui.StyleColorsLight()
        case .dark: ImGui.StyleColorsDark()
        }
    }
}

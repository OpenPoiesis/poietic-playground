//
//  Application+commands.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 12/02/2026.
//

import Foundation
import PoieticCore
import PoieticFlows
import CIimgui

extension Application {
//    func runCommand(_ command: any AppCommand, document: Document) {
//        let context = AppCommandContext(app: self)
//        do {
//            self.log("Running command '\(command.name)'")
//            try command.run(context)
//        }
//        catch {
//            self.logError("Command '\(command.name)' failed: \(error.message)")
//            if let underlyingError = error.underlyingError {
//                self.logError("Underlying error: \(String(describing: underlyingError))")
//            }
//            let title: String
//            switch error.severity {
//            case .fatal: title = "Fatal Error"
//            case .error: title = "Error"
//            }
//            
//            self.queueAlert(title: title, message: error.message)
//        }
//    }

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

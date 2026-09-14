//
//  EditCommands.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 15/02/2026.
//

import PoieticCore
import PoieticFlows
import Diagramming
import Foundation
import CIimgui

// FIXME: Move elsewhere
extension Application {
    static func setPasteboardText(_ text: String) throws (CommandError) {
        let platformIO = ImGui.GetPlatformIO().pointee
        guard let setPasteboardFn = platformIO.Platform_SetClipboardTextFn,
              let imguiContext = ImGui.GetCurrentContext()
        else {
            throw CommandError("Backend pasteboard configuration error", severity: .fatal)
        }
        
        setPasteboardFn(imguiContext, text)
    }
    // TODO: Move to application
    static func getPasteboardText() throws (CommandError) -> String? {
        let platformIO = ImGui.GetPlatformIO().pointee
        guard let getPasteboardFn = platformIO.Platform_GetClipboardTextFn,
              let imguiContext = ImGui.GetCurrentContext()
        else {
            throw CommandError("Backend pasteboard configuration error", severity: .fatal)
        }
        
        guard let result = getPasteboardFn(imguiContext) else {
            return nil
        }
        guard let string = String(cString: result, encoding: .utf8) else {
            return nil
        }
        return string
    }

}

class QuitApplicationCommand: AppCommand {
    var name: String { "quit" }

    @MainActor
    func run(_ context: Context) throws (CommandError) {
        context.app?.quitRequested = true
    }
}

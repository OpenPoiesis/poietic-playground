//
//  Application+Services.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 15/02/2026.
//

import CIimgui

extension Application {
    /// Set pasteboard from text. Returns `true` if successful, otherwise false.
    ///
    func setPasteboardText(_ text: String) -> Bool {
        let platformIO = ImGui.GetPlatformIO().pointee
        guard let setPasteboardFn = platformIO.Platform_SetClipboardTextFn,
              let imguiContext = ImGui.GetCurrentContext()
        else {
            self.logError("Can not set pasteboard text. Backend pasteboard configuration error.")
            return false
        }
        
        setPasteboardFn(imguiContext, text)
        return true
    }

    func getPasteboardText() -> String? {
        let platformIO = ImGui.GetPlatformIO().pointee
        guard let getPasteboardFn = platformIO.Platform_GetClipboardTextFn,
              let imguiContext = ImGui.GetCurrentContext()
        else {
            self.logError("Can not get pasteboard text. Backend pasteboard configuration error.")
            return nil
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

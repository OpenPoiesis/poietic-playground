//
//  InputFrame+ImGui.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 15/09/2026.
//

import CIimgui

extension MouseButtonMask {
    init(_ imGuiButtons: (Bool, Bool, Bool, Bool, Bool)) {
        var value: Self = .none
        if imGuiButtons.0 { value.insert(.left) }
        if imGuiButtons.1 { value.insert(.right) }
        if imGuiButtons.2 { value.insert(.middle) }
        if imGuiButtons.3 { value.insert(.other1) }
        if imGuiButtons.4 { value.insert(.other2) }
        
        self = value
    }
}

extension KeyModifiers {
    /// Create a key modifiers structure from ImGui keyboard chord.
    ///
    init(_ chord: ImGuiKeyChord) {
        var value: KeyModifiers = .none
        
        if chord & ImGuiMod_Ctrl.rawValue != 0 {
            value.formUnion(.command)
        }
        if chord & ImGuiMod_Shift.rawValue != 0 {
            value.formUnion(.shift)
        }
        if chord & ImGuiMod_Alt.rawValue != 0 {
            value.formUnion(.alt)
        }

        self = value
    }
}

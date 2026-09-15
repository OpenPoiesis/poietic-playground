//
//  InputFrame.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 14/09/2026.
//

import CIimgui
import Diagramming // TODO: Remove this import once we unite Vector2D and Point (not needed here)

extension Vector2D {
    func lengthSquared() -> Double {
        return (self * self).sum()
    }
}

/// Key modifiers for a tool event.
///
/// - SeeAlso: ``ToolEvent``
///
struct KeyModifiers: OptionSet, CustomStringConvertible {
    var rawValue: UInt8
    
    /// Command on MacOS or Control on other systems.
    static let none: KeyModifiers = []
    static let command = KeyModifiers(rawValue: 1)
    static let shift = KeyModifiers(rawValue: 2)
    static let alt = KeyModifiers(rawValue: 4)
    
    var description: String {
        var desc = ""
        if self.contains(.command) { desc += "⌘"}
        if self.contains(.shift) { desc += "⇧"}
        if self.contains(.alt) { desc += "⎇"}
        return desc
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

enum MouseButton: Equatable, CaseIterable, CustomStringConvertible {
    case left
    case right
    case middle
    case other1
    case other2
    
    var mask: MouseButtonMask {
        switch self {
        case .left: .left
        case .right: .right
        case .middle: .middle
        case .other1: .other1
        case .other2: .other2
        }
    }
    var description: String {
        switch self {
        case .left: "L"
        case .right: "R"
        case .middle: "M"
        case .other1: "O₁"
        case .other2: "O₂"
        }
    }
}

/// Convenience structure with explicit names and with subscript lookup.
///
struct MouseButtonValues<Value> {
    var left: Value
    var right: Value
    var middle: Value
    var other1: Value
    var other2: Value
    
    init(_ pairs: KeyValuePairs<MouseButton, Value>, default defaultValue: Value) {
        var left: Value = defaultValue
        var right: Value = defaultValue
        var middle: Value = defaultValue
        var other1: Value = defaultValue
        var other2: Value = defaultValue
        
        for (key, value) in pairs {
            switch key {
            case .left: left = value
            case .right: right = value
            case .middle: middle = value
            case .other1: other1 = value
            case .other2: other2 = value
            }
        }
        self.left = left
        self.right = right
        self.middle = middle
        self.other1 = other1
        self.other2 = other2
    }

    subscript(button: MouseButton) -> Value {
        get {
            switch button {
            case .left: left
            case .right: right
            case .middle: middle
            case .other1: other1
            case .other2: other2
            }
        }
        set(value) {
            switch button {
            case .left: left = value
            case .right: right = value
            case .middle: middle = value
            case .other1: other1 = value
            case .other2: other2 = value
            }
        }
    }
}


struct MouseButtonMask: OptionSet, CustomStringConvertible {
    let rawValue: UInt8
    init(rawValue: UInt8) {
        self.rawValue = rawValue
    }
    
    var isDown: Bool { rawValue != 0 }
    
    static let none: MouseButtonMask = []
    static let left = MouseButtonMask(rawValue: 1 << 0)
    static let right = MouseButtonMask(rawValue: 1 << 1)
    static let middle = MouseButtonMask(rawValue: 1 << 2)
    static let other1 = MouseButtonMask(rawValue: 1 << 3)
    static let other2 = MouseButtonMask(rawValue: 1 << 4)
    
    var description: String {
        var desc: String = "["
        if self.contains(.left) { desc += "L" }
        if self.contains(.right) { desc += "R" }
        if self.contains(.middle) { desc += "M" }
        if self.contains(.other1) { desc += "O₁" }
        if self.contains(.other2) { desc += "O₂" }
        desc += "]"
        return desc

    }
    
    init(_ imGuiButtons: (Bool, Bool, Bool, Bool, Bool)) {
        var value: Self = .none
        if imGuiButtons.0 { value.insert(.left) }
        if imGuiButtons.1 { value.insert(.right) }
        if imGuiButtons.2 { value.insert(.middle) }
        if imGuiButtons.3 { value.insert(.other1) }
        if imGuiButtons.4 { value.insert(.other2) }

        self = value
    }
    // Make a Sequence by providing an iterator
    var buttons: some Sequence<MouseButton> {
        return sequence(state: UInt8(0)) { currentBit in
            while currentBit < 8 {
                let bitValue: UInt8 = 1 << currentBit
                currentBit += 1
                
                if rawValue & bitValue != 0 {
                    switch bitValue {
                    case 1 << 0: return .left
                    case 1 << 1: return .right
                    case 1 << 2: return .middle
                    case 1 << 3: return .other1
                    case 1 << 4: return .other2
                    default: break
                    }
                }
            }
            return nil
        }
    }
}


struct InputFrame {
    var pointer: Vector2D
    var pointerDelta: Vector2D
    var buttonsDown: MouseButtonMask
    var buttonsClicked: MouseButtonMask
    var buttonsReleased: MouseButtonMask
    var clickCounts: MouseButtonValues<Int>
    var dragMaxDistance: MouseButtonValues<Double>
    var modifiers: KeyModifiers
    var scroll: Vector2D
    // Used to cancel tool events
    var escapePressed: Bool
}

struct InputState {
    enum PointerState: Equatable {
        /// Pointer or mouse is up – idle.
        case idle
        /// Pointer or mouse is pressed, not yet moved.
        ///
        /// The associated value is the first button that triggered the state.
        case pressed(MouseButton)
        /// Pointer or mouse has been moved.
        ///
        /// The associated value is the first button that triggered the state.
        case dragging(MouseButton)
    }

    var pointerState: PointerState = .idle

//    var pointer: Vector2D? = nil
    var previousModifiers: KeyModifiers = .none
    var wasMouseInViewport: Bool = false
}


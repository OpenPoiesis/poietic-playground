//
//  ToolEvent.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 03/02/2026.
//
import CIimgui
import Diagramming



enum ToolEventType {
    /// Mouse button pressed this plane
    case pointerDown
    /// Mouse button moved this plane
    case pointerMove
    /// Mouse released this plane
    ///
    case pointerUp
    
    /// Movement exceeded threshold after button is already down
    case dragStart
    /// Continues while dragging
    case dragMove
    /// Button released while in drag state
    case dragEnd
    
    case dragCancel

    case click
    case doubleClick
    case tripleClick


    case hoverStart
//    case hoverMove // Not triggered, use pointerMove
    case hoverEnd

    case modifierChange
    
//    case contextMenu
    
    case scroll
    
    case pinchStart
    case pinchUpdate
    case pinchEnd
}

// TODO: Make ToolEvent imgui-free
/// Structure encapsulating information about a canvas tool event.
struct ToolEvent: CustomDebugStringConvertible {
    let type: ToolEventType
    
    let screenPos: Vector2D
    let delta: Vector2D

    /// Which button(s) are down
    let buttonsDown: MouseButtonMask
    let modifiers: KeyModifiers

    /// Which button(s) triggered this event
    let triggerButton: MouseButton?
    let scrollDelta: Vector2D
    let scale: Float

    var debugDescription: String {
        let desc = "\(type) P:\(screenPos) ∆:\(delta) B:\(buttonsDown) M:\(modifiers) T:\(triggerButton, default:"-")"
        return desc
    }
    
    struct Body {
        let screenPos: Vector2D
        let delta: Vector2D
        let buttonsDown: MouseButtonMask
        let modifiers: KeyModifiers
    }
    
    init(_ type: ToolEventType,
         screenPos: Vector2D = Vector2D(),
         delta: Vector2D = Vector2D(),
         buttonsDown: MouseButtonMask = .none,
         modifiers: KeyModifiers = .none,
         triggerButton: MouseButton? = nil,
         scrollDelta: Vector2D = Vector2D(),
         scale: Float = 1.0)
    {
        self.type = type
        self.screenPos = screenPos
        self.delta = delta
        self.buttonsDown = buttonsDown
        self.modifiers = modifiers
        self.triggerButton = triggerButton
        self.scrollDelta = scrollDelta
        self.scale = scale
    }
    
    init(_ type: ToolEventType,
         body: Body,
         triggerButton: MouseButton? = nil,
         scrollDelta: Vector2D = .zero,
         scale: Float = 1.0)
    {
        self.type = type
        self.screenPos = body.screenPos
        self.delta = body.delta
        self.buttonsDown = body.buttonsDown
        self.modifiers = body.modifiers
        self.triggerButton = triggerButton
        self.scrollDelta = scrollDelta
        self.scale = scale
    }
    
    init(_ gesture: GestureEvent, input: InputFrame) {
        self.screenPos = input.pointer
        self.delta = input.pointerDelta
        self.buttonsDown = .none
        self.modifiers = input.modifiers
        self.triggerButton = nil
        
        switch gesture {
        case .pinch(let phase, scale: let scale):
            self.type = switch phase {
            case .start: .pinchStart
            case .update: .pinchUpdate
            case .end: .pinchEnd
            }
            self.scrollDelta = .zero
            self.scale = scale
        }
    }

}

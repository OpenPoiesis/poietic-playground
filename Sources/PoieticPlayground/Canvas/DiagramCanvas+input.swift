//
//  DiagramCanvas+input.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 04/02/2026.
//
import Diagramming

// TODO: Create CanvasInputRecognizer:

//class CanvasInputRecognizer {
//    let state: InputState = InputState()
//    func recognizeEvents(_ io: ImGuiIO, isPointerOver: Bool) -> [ToolEvent] {
//        return []
//    }
//}

// TODO: Consider moving this outside of canvas. We need inputState and isPointerOver
extension DiagramCanvas {
    static let PointerDragThreshold:Double = 6.0 // TODO: Check whether this is a good value
    
    // MARK: - Input Handling
    func recognizeInput(_ input: InputFrame) -> [ToolEvent] {
        var events: [ToolEvent] = []
       
        // Current state
        let eventBody = ToolEvent.Body(
            screenPos: input.pointer,
            delta: input.pointerDelta,
            buttonsDown: .none,
            modifiers: input.modifiers
        )

        // Viewport check and Hover Events
        //
        // Mouse left viewport while idle - bail completely
        if !isPointerOver && (inputState.pointerState == .idle) {
            if inputState.wasMouseInViewport {
                let event = ToolEvent(.hoverEnd, body: eventBody)
                events.append(event)
            }
            inputState.wasMouseInViewport = false
            return events
        }

        // Mouse left viewport during operation - continue but emit HoverEnd
        if !isPointerOver && inputState.wasMouseInViewport {
            let event = ToolEvent(.hoverEnd, body: eventBody)
            events.append(event)
            inputState.wasMouseInViewport = false
        }
        // Mouse returned to viewport - emit HoverStart
        if isPointerOver && !inputState.wasMouseInViewport {
            let event = ToolEvent(.hoverStart, body: eventBody)
            events.append(event)
            inputState.wasMouseInViewport = true
        }
        
        // Pointer Events
        for button in input.buttonsClicked.buttons {
            let event = ToolEvent(.pointerDown,
                                  body: eventBody,
                                  triggerButton: button)
            events.append(event)
        }
        
        if input.pointerDelta.lengthSquared() > 0.0 {
            let event = ToolEvent(.pointerMove, body: eventBody)
            events.append(event)
        }
        
        for button in input.buttonsReleased.buttons {
            let event = ToolEvent(.pointerUp,
                                  body: eventBody,
                                  triggerButton: button)
            events.append(event)
        }
        
        // Modifier Change
        if input.modifiers != inputState.previousModifiers {
            let event = ToolEvent(.modifierChange, body: eventBody)
            events.append(event)
            inputState.previousModifiers = input.modifiers
        }
        
        // === SCROLL EVENT ===
        if input.scroll.lengthSquared() > 0.0 {
            let event = ToolEvent(.scroll, body: eventBody, scrollDelta: input.scroll)
            events.append(event)
        }
        
        // Input State Machine and Gesture Recognition
        switch inputState.pointerState {
        case .idle:
            for button in input.buttonsClicked.buttons {
                inputState.pointerState = .pressed(button)
                break // Track first button only
            }
            
        case .pressed(let dragButton):
            let distance = input.dragMaxDistanceSqr[dragButton]

            if input.buttonsReleased.contains(dragButton.mask) {
                // TODO: The click count handling does not seem to work
                let clickCount = input.clickCounts[dragButton]
                let eventType: ToolEventType?
                if clickCount == 1 {
                    eventType = .click
                }
                else if clickCount == 2 {
                    eventType = .doubleClick
                }
                else if clickCount >= 3 {
                    eventType = .tripleClick
                }
                else {
                    eventType = nil
                }
                if let eventType {
                    let event = ToolEvent(eventType, body: eventBody, triggerButton: dragButton)
                    events.append(event)
                }
                inputState.pointerState = .idle
            }
                // Check if drag threshold exceeded
            else if distance >= Self.PointerDragThreshold {
                inputState.pointerState = .dragging(dragButton)
                
                let event = ToolEvent(.dragStart, body: eventBody, triggerButton: dragButton)
                events.append(event)
            }
            // Escape cancels the press
            else if input.escapePressed {
                inputState.pointerState = .idle
            }

        case .dragging(let dragButton):
            // Continue dragging
            if input.buttonsDown.contains(dragButton.mask) {
                if input.pointerDelta.lengthSquared() > 0.0 {
                    let event = ToolEvent(.dragMove, body: eventBody, triggerButton: dragButton)
                    events.append(event)
                }
            }
            // Drag ended
            else if input.buttonsReleased.contains(dragButton.mask) {
                let event = ToolEvent(.dragEnd, body: eventBody, triggerButton: dragButton)
                events.append(event)
                inputState.pointerState = .idle
            }
            // Escape cancels drag
            if input.escapePressed {
                let event = ToolEvent(.dragCancel, body: eventBody, triggerButton: dragButton)
                events.append(event)
                inputState.pointerState = .idle
            }
        }
        
        return events
    }
}

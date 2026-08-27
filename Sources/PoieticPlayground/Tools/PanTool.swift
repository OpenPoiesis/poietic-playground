//
//  PanTool.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 05/02/2026.
//

import CIimgui
import Diagramming

class PanTool: CanvasTool {
    static let MinZoom: Double = 0.1
    static let MaxZoom: Double = 10.0
    static let ZoomSensitivity: Double = 0.1
    static let ScrollSensitivity: Double = 4.0
    
    enum State {
        case idle
        case panning
        case pinching
    }
    
    override var name: String { "pan"}
    override var iconKey: IconKey { .hand }
    
    var cursor: ImGuiMouseCursor_ = ImGuiMouseCursor_Arrow
    var previousScreenPos: ImVec2 = ImVec2()
    var state: State = .idle
    
    override func handleEvent(_ event: ToolEvent) -> EngagementResult {
        switch event.type {
        case .dragStart: return self.dragStart(event)
        case .dragMove: return self.dragMove(event)
        case .dragEnd: return self.dragEnd(event)
        case .dragCancel: return self.dragCancel(event)
        case .scroll: return self.scroll(event)
        case .pinchStart: return self.pinchStart(event)
        case .pinchUpdate: return self.pinchUpdate(event)
        case .pinchEnd: return self.pinchEnd(event)
        default: return .pass
        }
    }
    
    func dragStart(_ event: ToolEvent) -> EngagementResult {
        guard event.triggerButton == .left else { return .pass }
        
        self.previousScreenPos = event.screenPos
        self.state = .panning
        self.cursor = ImGuiMouseCursor_Hand
        return .engaged
    }
    
    func dragMove(_ event: ToolEvent) -> EngagementResult {
        guard state == .panning else { return .pass }
        guard let canvas else { return .pass }
        
        let screenOffset = event.screenPos - self.previousScreenPos
        let canvasOffset = Vector2D(screenOffset) / Double(canvas.zoomLevel)
        canvas.setView(offset: canvas.viewOffset - canvasOffset,
                       zoom: canvas.zoomLevel)
        
        self.previousScreenPos = event.screenPos
        
        self.cursor = ImGuiMouseCursor_Hand
        return .engaged
    }
    
    func dragEnd(_ event: ToolEvent) -> EngagementResult {
        guard state == .panning else { return .pass }
        guard let canvas else { return .pass }
        
        let screenOffset = event.screenPos - self.previousScreenPos
        let canvasOffset = Vector2D(screenOffset) / Double(canvas.zoomLevel)
        canvas.setView(offset: canvas.viewOffset - canvasOffset,
                       zoom: canvas.zoomLevel)
        
        state = .idle
        cursor = ImGuiMouseCursor_Arrow
        return .consumed
    }
    
    func dragCancel(_ event: ToolEvent) -> EngagementResult {
        cursor = ImGuiMouseCursor_Arrow
        state = .idle
        return .consumed
    }
    
    func pinchStart(_ event: ToolEvent) -> EngagementResult {
        guard state == .idle else { return .pass }
        self.state = .pinching
        return .consumed
    }
    func pinchUpdate(_ event: ToolEvent) -> EngagementResult {
        guard state == .pinching,
              let canvas, event.scale > 0 else
        { return .pass }
        
        let zoomFactor = Double(event.scale)
        let newZoom = max(min((canvas.zoomLevel * zoomFactor), Self.MaxZoom), Self.MinZoom)
        
        zoom(to: newZoom, at: event.screenPos, canvas: canvas)

        return .consumed
    }
    func pinchEnd(_ event: ToolEvent) -> EngagementResult {
        guard state == .pinching else { return .pass }
        self.state = .idle
        return .consumed
    }
    
    // TODO: Make it smooth-er + add inertia
    func scroll(_ event: ToolEvent) -> EngagementResult {
        guard let canvas else { return .pass }

        // Cmd/Ctrl + scroll zooms
        if event.modifiers.contains(.command) {
            let zoomFactor = 1.0 + (Double(event.scrollDelta.y) * Self.ZoomSensitivity)
            let newZoom = max(min(canvas.zoomLevel * zoomFactor, Self.MaxZoom), Self.MinZoom)
            zoom(to: newZoom, at: event.screenPos, canvas: canvas)
        }
        else {
            let screenDelta = Vector2D(event.scrollDelta) * Self.ScrollSensitivity
            let worldDelta = screenDelta / canvas.zoomLevel
            canvas.setView(offset: canvas.viewOffset - worldDelta, zoom: canvas.zoomLevel)
        }
        
        return .consumed
    }
    
    private func zoom(to newZoom: Double, at screenPos: ImVec2, canvas: DiagramCanvas) {
        let worldBefore: Vector2D = canvas.screenToWorld(screenPos)
        let viewportOffset = Vector2D(screenPos - canvas.canvasPos) / newZoom
        canvas.setView(offset: worldBefore - viewportOffset, zoom: newZoom)
    }
}


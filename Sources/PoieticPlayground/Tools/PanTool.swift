//
//  PanTool.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 05/02/2026.
//

import CIimgui
import Diagramming

class NavigationInteraction: ToolInteraction {
    static let MinZoom: Double = 0.1
    static let MaxZoom: Double = 10.0
    static let ZoomSensitivity: Double = 0.1
    static let ScrollSensitivity: Double = 4.0

    unowned let canvas: DiagramCanvas

    enum State {
        case idle
        case panning
        case pinching
    }

    var previousScreenPos: Vector2D = .zero
    var cursor: ImGuiMouseCursor_ = ImGuiMouseCursor_Arrow
    var state: State = .idle
    
    init(canvas: DiagramCanvas) {
        self.canvas = canvas
    }

    
    func begin() {
        previousScreenPos = .zero
        state = .idle
    }
    
    func end() {
        previousScreenPos = .zero
        state = .idle
    }
    
    func handleEvent(_ event: ToolEvent) -> EventDisposition {
        switch event.type {
        case .dragStart: return self.dragStart(event)
        case .dragMove: return self.dragMove(event)
        case .dragEnd: return self.dragEnd(event)
        case .dragCancel: return self.dragCancel(event)
        case .scroll: return self.scroll(event)
        case .pinchStart: return self.pinchStart(event)
        case .pinchUpdate: return self.pinchUpdate(event)
        case .pinchEnd: return self.pinchEnd(event)
        default: return .ignored
        }
    }
    
    func dragStart(_ event: ToolEvent) -> EventDisposition {
        guard event.triggerButton == .left else { return .ignored }
        
        self.previousScreenPos = event.screenPos
        self.state = .panning
        self.cursor = ImGuiMouseCursor_Hand
        return .engaged
    }
    
    func dragMove(_ event: ToolEvent) -> EventDisposition {
        guard state == .panning else { return .ignored }
        
        let screenOffset = event.screenPos - self.previousScreenPos
        let canvasOffset = Vector2D(screenOffset) / Double(canvas.zoomLevel)
        canvas.setView(offset: canvas.viewOffset - canvasOffset,
                       zoom: canvas.zoomLevel)
        
        self.previousScreenPos = event.screenPos
        
        self.cursor = ImGuiMouseCursor_Hand
        return .engaged
    }
    
    func dragEnd(_ event: ToolEvent) -> EventDisposition {
        guard state == .panning else { return .ignored }
        
        let screenOffset = event.screenPos - self.previousScreenPos
        let canvasOffset = Vector2D(screenOffset) / Double(canvas.zoomLevel)
        canvas.setView(offset: canvas.viewOffset - canvasOffset,
                       zoom: canvas.zoomLevel)
        
        state = .idle
        cursor = ImGuiMouseCursor_Arrow
        return .handled
    }
    
    func dragCancel(_ event: ToolEvent) -> EventDisposition {
        cursor = ImGuiMouseCursor_Arrow
        state = .idle
        return .handled
    }
    
    func pinchStart(_ event: ToolEvent) -> EventDisposition {
        guard state == .idle else { return .ignored }
        self.state = .pinching
        return .handled
    }
    func pinchUpdate(_ event: ToolEvent) -> EventDisposition {
        guard state == .pinching,
              event.scale > 0 else
        { return .ignored }
        
        let zoomFactor = Double(event.scale)
        let newZoom = max(min((canvas.zoomLevel * zoomFactor), Self.MaxZoom), Self.MinZoom)
        
        zoom(to: newZoom, at: event.screenPos, canvas: canvas)

        return .handled
    }
    func pinchEnd(_ event: ToolEvent) -> EventDisposition {
        guard state == .pinching else { return .ignored }
        self.state = .idle
        return .handled
    }
    
    // TODO: Make it smooth-er + add inertia
    func scroll(_ event: ToolEvent) -> EventDisposition {
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
        
        return .handled
    }
    
    private func zoom(to newZoom: Double, at screenPos: Vector2D, canvas: DiagramCanvas) {
        let worldBefore: Vector2D = canvas.screenToWorld(screenPos)
        let viewportOffset = Vector2D(screenPos - Vector2D(canvas.canvasPos)) / newZoom
        canvas.setView(offset: worldBefore - viewportOffset, zoom: newZoom)
    }

}

class PanTool: CanvasTool {
    static let type: CanvasToolType = .pan
    static let iconKey: IconKey = .hand
    static let isRepeating: Bool = false

    var isLocked: Bool = false
    var selectedPaletteItem: String? = nil

    func makeInteraction(context: ToolContext) -> any ToolInteraction {
        return NavigationInteraction(canvas: context.canvas)
    }
}


//
//  DiagramCanvas+drawing.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 05/02/2026.
//

// TODO: [IMPORTANT] This whole file contains early prototype of all canvas drawing and needs to be split.

import CIimgui
import Ccairo
import PoieticCore
import PoieticFlows
import Diagramming
import Foundation

enum DetailLevel {
    case overview    // Visible at very low zoom (0.1x - 0.5x)
    case standard    // Visible at normal zoom (0.5x - 2.0x)
    case detailed    // Visible at high zoom (2.0x - 10.0x)
    case debug       // Only at very high zoom (10.0x+)
    
    var range: ClosedRange<Double> {
        switch self {
        case .overview: 0.1...0.5
        case .standard: 0.5...2.0
        case .detailed: 2.0...10.0
        case .debug: 10.0...100.0
        }
    }
    
    var minZoom: Float {
        switch self {
        case .overview: return 0.1
        case .standard: return 0.5
        case .detailed: return 2.0
        case .debug: return 10.0
        }
    }
    
    var maxZoom: Float {
        switch self {
        case .overview: return 0.5
        case .standard: return 2.0
        case .detailed: return 10.0
        case .debug: return 100.0
        }
    }
}

extension DiagramCanvas {
    func drawGrid(_ context: CairoDrawingContext) {
        guard showGrid else { return }
        context.save()
        
        let worldViewSize = Vector2D(canvasSize) / zoomLevel
        let worldTopLeft = viewOffset
        let worldBottomRight = viewOffset + worldViewSize
        
        let gridColor = style.shapeStyle(class: .grid)?.stroke ?? CanvasStyle.DefaultStrokeColor
        context.setColor(gridColor)
        context.setLineWidth(0.5)
        
        // Vertical lines
        let startX = floor(worldTopLeft.x / gridSize) * gridSize
        let endX = ceil(worldBottomRight.x / gridSize) * gridSize
        for x in stride(from: startX, through: endX, by: gridSize) {
            let sx = (x - viewOffset.x) * zoomLevel
            context.addLine(from: Vector2D(sx, 0), to: Vector2D(sx, Double(canvasSize.y)))
        }
        
        // Horizontal lines
        let startY = floor(worldTopLeft.y / gridSize) * gridSize
        let endY = ceil(worldBottomRight.y / gridSize) * gridSize
        for y in stride(from: startY, through: endY, by: gridSize) {
            let sy = (y - viewOffset.y) * zoomLevel
            context.addLine(from: Vector2D(0, sy), to: Vector2D(Double(canvasSize.x), sy))
        }
        
        context.stroke()
        context.restore()
    }
}

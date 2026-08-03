//
//  CairoDiagramSceneRenderer.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 12/07/2026.
//

import PoieticCore
import Diagramming

class CairoDiagramSceneRenderer: DiagramSceneRenderer {
    static let DebugColor = Color.screenRed.withTransparency(0.5)

    typealias Context = CairoDrawingContext
    
    let style: CanvasStyle
    let debug: Bool
    
    init(style: CanvasStyle, debug: Bool = false) {
        self.style = style
        self.debug = debug
    }
    
    func renderBlock(_ entity: RuntimeEntity, context: Context) {
        // TODO: [REFACTORING] Separate pictogram rendering into renderPictogram(...)
        guard let pictogramNode: RuntimeEntity = entity.target(CanvasNode.Pictogram.self),
              let pictComp: PictogramCanvasNode = pictogramNode.component()
        else { return }
        let nodeStyle: CanvasNodeStyle? = entity.component()
        
        let pictogram = pictComp.pictogram
        
        switch context.overlay {
        case .main:
            let shapeStyle = style.shapeStyle(class: nodeStyle?.class ?? .pictogram)
            context.setColor(shapeStyle?.stroke ?? CanvasStyle.DefaultStrokeColor)
            context.strokePath(pictogram.path)
        case .highlight:
            // If we do not have node style set we do not know whether we need a highlight
            guard let nodeStyle else { break }
            
            if nodeStyle.modifiers.contains(.selected) {
                let shapeStyle = style.shapeStyle(class: .highlight, modifiers: .selected)
                context.setColor(shapeStyle?.fill ?? CanvasStyle.DefaultFillColor)
                context.fillPath(pictogram.mask)
                context.setColor(shapeStyle?.stroke ?? CanvasStyle.DefaultStrokeColor)
                context.strokePath(pictogram.mask)
            }
            if nodeStyle.modifiers.contains(.allowed) {
                let shapeStyle = style.shapeStyle(class: .highlight, modifiers: .allowed)
                context.setColor(shapeStyle?.fill ?? CanvasStyle.DefaultFillColor)
                context.fillPath(pictogram.mask)
                context.setColor(shapeStyle?.stroke ?? CanvasStyle.DefaultStrokeColor)
                context.strokePath(pictogram.mask)
            }
            else if nodeStyle.modifiers.contains(.notAllowed) {
                let shapeStyle = style.shapeStyle(class: .highlight, modifiers: .notAllowed)
                context.setColor(shapeStyle?.fill ?? CanvasStyle.DefaultFillColor)
                context.fillPath(pictogram.mask)
                context.setColor(shapeStyle?.stroke ?? CanvasStyle.DefaultStrokeColor)
                context.strokePath(pictogram.mask)
            }
        default: break
        }
        
    }
    
    func renderConnector(_ entity: RuntimeEntity, context: Context) {
        guard let stroke: ConnectorStroke = entity.component()
        else { return }
        
        let nodeStyle: CanvasNodeStyle? = entity.component()
        
        switch context.overlay {
        case .main:
            let shapeStyle = style.shapeStyle(class: nodeStyle?.class ?? .normal)
            context.setColor(shapeStyle?.stroke ?? CanvasStyle.DefaultStrokeColor)
            context.setLineWidth(shapeStyle?.lineWidth ?? 1.0)
            
            // Open curves
            if let path = stroke.body {
                context.addPath(path)
            }
            if let path = stroke.headArrowhead {
                context.addPath(path)
            }
            if let path = stroke.tailArrowhead {
                context.addPath(path)
            }
            context.stroke()
            
            // Filled curves
            if stroke.isFilled, let path = stroke.body {
                context.setColor(shapeStyle?.fill ?? CanvasStyle.DefaultFillColor)
                context.addPath(path)
                context.fill()
            }
        case .highlight:
            // No node style  - we do not know what highlight to draw
            // No wire - we do not know how to draw the highlight
            guard let nodeStyle: CanvasNodeStyle = entity.component(),
                  let wire: ConnectorWire = entity.component()
            else { break }
            
            // Assumption: Style colours are transparent, therefore we can draw them on top of each other
            if nodeStyle.modifiers.contains(.selected) {
                let shapeStyle = style.shapeStyle(class: .highlight, modifiers: .selected)
                
                // TODO: Remove this debug
                let wirePath = BezierPath(polyline: wire.points)
                context.save()
                context.setColor(Color(red: 1.0, green: 0.8, blue: 0.0))
                context.setLineWidth(4)
                context.strokePath(wirePath)
                
                context.setColor(shapeStyle?.fill ?? CanvasStyle.DefaultFillColor)
                // TODO: [REFACTORING] Precompute this on connector as ConnectorOutline
                let outline = wirePath.inflated(by: 10.0)
                context.fillPath(outline)
                
                context.restore()
            }
            
        default:
            break
        }
        
    }
    func renderPictogram(_ entity: RuntimeEntity, context: Context) {
        guard context.overlay == .main else { return }
//        debugPrint("WARNING: \(#function) not implemented")
    }
    func renderLabel(_ entity: RuntimeEntity, context: Context) {
        guard context.overlay == .main,
              let label: LabelCanvasNode = entity.component()
        else { return }
        
        let nodeStyle: CanvasNodeStyle? = entity.component()
        let labelStyle = style.labelStyle(class: nodeStyle?.class ?? .label)
        
        context.setFontSize(labelStyle?.size ?? CanvasStyle.DefaultFontSize)
        context.setColor(labelStyle?.color ?? CanvasStyle.DefaultLabelColor)
        context.showText(label.text, at: .zero)
    }
    func renderValueIndicator(_ entity: RuntimeEntity, context: Context) {
        guard context.overlay == .indicator else { return }
//        debugPrint("WARNING: \(#function) not implemented")
    }
    func renderIssueIndicator(_ entity: RuntimeEntity, context: Context) {
        guard context.overlay == .indicator else { return }
//        debugPrint("WARNING: \(#function) not implemented")
    }
    func renderColorSwatch(_ entity: RuntimeEntity, context: Context) {
        guard context.overlay == .main,
              let swatch: ColorSwatchCanvasNode = entity.component()
        else { return }
        
        let color = style.adaptableColor(swatch.colorKey,
                                         default: DefaultAdaptableColors[swatch.colorKey] ?? Color.init(gray: 0.5))
        let size = style.metric(.colorSwatchSize, default: ColorSwatchCanvasNode.DefaultSize)
        context.setColor(color)
        let rect = Rect2D(center: .zero, size: Vector2D(size, size))
        context.fillRect(origin: rect.origin, size: rect.size)
    }

    func renderNodeExtras(_ entity: RuntimeEntity, context: Context) {
        guard debug else { return }
        let visibility: Visibility? = entity.component()
        guard visibility != .hidden else { return }

        if let shape: CollisionShape = entity.component() {
            context.setColor(Self.DebugColor)
            context.setLineWidth(1.0)
            let path = shape.toPath()
            context.strokePath(path)
        }
        if let region: TouchRegion = entity.component() {
            // draw touch region outline
        }
    }
    
    // MARK: - Application Specific
    func renderUnknown(_ entity: RuntimeEntity, context: Context) {
        if entity.contains(CanvasHandle.self) {
            renderHandle(entity, context: context)
        }
    }

    func renderHandle(_ entity: RuntimeEntity, context: Context) {
        guard context.overlay == .highlight,
              let handle: CanvasHandle = entity.component()
        else { return }
        
        let size = style.metric(.handleSize, default: CanvasHandle.DefaultSize)

        if let style = style.shapeStyle(class: .handle) {
            if let color = style.stroke {
                context.setColor(color)
            }
            context.setLineWidth(style.lineWidth)
        }
        else {
            context.setColor(Color(gray: 0.5))
        }
        let path = BezierPath(circle: .zero, radius: size / 2.0)
        context.fillPath(path)
    }

}

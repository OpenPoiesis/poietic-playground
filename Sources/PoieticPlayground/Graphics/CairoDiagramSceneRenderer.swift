//
//  CairoDiagramSceneRenderer.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 12/07/2026.
//

import PoieticCore
import Diagramming
import Foundation

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

    /// - Expectations:
    ///     - parent's represented entity has NumericValueSample()
    func renderValueIndicator(_ entity: RuntimeEntity, context: Context) {
        guard context.overlay == .indicator,
              let indicator: ValueIndicatorCanvasNode = entity.component()
        else { return }

        // Get probed value and value bounds from the probed entity
        let value: Double?
        let bounds: ValueBounds
        
        if let probed = entity.parent?.target(RepresentationOf.self) {
            (value, bounds) = probed.numericProbe()
        }
        else {
            value = nil
            bounds = ValueBounds(min: 0.0, max: 1.0)
        }
        
        let nodeStyle: CanvasNodeStyle = entity.component()
                                            ?? CanvasNodeStyle(class: .valueIndicator)

        let indicatorLabel: String
        if let value {
            indicatorLabel = value.formatted(.number.precision(.significantDigits(1...2)))
        }
        else {
            indicatorLabel = ""
        }
        
        let frame = Rect2D(center: .zero, size: indicator.size)

        drawValueIndicatorBar(context,
                              frame: frame,
                              value: value,
                              bounds: bounds,
                              orientation: indicator.orientation)
        // TODO: Draw label
        let labelStyle = style.labelStyle(class: .valueIndicator)
        
        context.setFontSize(labelStyle?.size ?? CanvasStyle.DefaultFontSize)
        context.setColor(labelStyle?.color ?? CanvasStyle.DefaultLabelColor)
        context.showText(indicatorLabel, center: .zero)

        //        context.setFontSize(style.valueIndicatorStyle.fontSize)
//        let te = context.textExtents(indicatorLabel)
//        let position = Vector2D(anchor.x - (te.width / 2) - te.x_bearing,
//                                anchor.y - (te.height / 2) - te.y_bearing)
//        
//        context.setColor(style.indicatorLineColor)
//        context.showText(indicatorLabel, at: position)
    }

    func drawValueIndicatorBar(_ context: Context,
                               frame: Rect2D,
                               value: Double?,
                               bounds: ValueBounds,
                               orientation: ValueIndicatorCanvasNode.Orientation)
    {
        let ValueIndicatorBarPadding: Double = 2.0
//        let fullRect = Rect2D(position: -rect.size / 2, size: rect.size)
        let rect = frame.grown(by: -ValueIndicatorBarPadding)
        let size = rect.size // Adjusted size by padding
        
        let backgroundStyle = style.shapeStyle(class: .valueIndicator)
                ?? CanvasStyle.DefaultValueIndicatorStyle
        context.drawRect(frame, style: backgroundStyle)

        guard let value else {
            let rectStyle = style.shapeStyle(class: .valueIndicator, modifiers: .empty)
                    ?? CanvasStyle.DefaultIndicatorEmptyStyle

            context.drawRect(rect, style: rectStyle)
            return
        }
        
        let barStyle = switch bounds.state(of: value) {
        case .positive: style.shapeStyle(class: .valueIndicator, modifiers: .positive)
                        ?? CanvasStyle.DefaultIndicatorNormalStyle
        case .negative: style.shapeStyle(class: .valueIndicator, modifiers: .negative)
                        ?? CanvasStyle.DefaultIndicatorNegativeStyle
        case .overflow: style.shapeStyle(class: .valueIndicator, modifiers: .overflow)
                        ?? CanvasStyle.DefaultIndicatorOverflowStyle
        case .underflow: style.shapeStyle(class: .valueIndicator, modifiers: .underflow)
                        ?? CanvasStyle.DefaultIndicatorUnderflowStyle
        }

        guard bounds.range.magnitude > Double.standardEpsilon else {
            context.drawRect(rect, style: barStyle)
            return
        }

        let valueBar: Rect2D
        let line: LineSegment
        
        switch orientation {
        case .horizontal:
            let scaledOrigin = bounds.normalizedBaseline * size.x
            let scaledValue = bounds.normalized(value) * size.x

            valueBar = Rect2D(x: rect.origin.x + scaledOrigin,
                              y: rect.origin.y,
                              width: scaledValue - scaledOrigin,
                              height: size.y)
            
            line = LineSegment(
                from: Vector2D(x: rect.origin.x + scaledOrigin, y: rect.origin.y),
                to: Vector2D(x: rect.origin.x + scaledOrigin, y: rect.origin.y + size.y)
            )

        case .vertical:
            let scaledOrigin = bounds.normalizedBaseline * size.y
            let scaledValue = bounds.normalized(value) * size.y

            valueBar = Rect2D(x: rect.origin.x,
                              y: rect.origin.y + scaledOrigin,
                              width: size.x,
                              height: scaledValue - scaledOrigin)

            line = LineSegment(
                from: Vector2D(x: rect.origin.x, y: rect.origin.y + scaledOrigin),
                to: Vector2D(x: rect.origin.x + size.x, y: rect.origin.y + scaledOrigin)
            )
        }
        context.drawRect(valueBar, style: barStyle)

        if let lineStyle = style.shapeStyle(class: .valueIndicatorLine),
           let color = lineStyle.stroke
        {
            context.setColor(color)
            context.addLine(from: line.start, to: line.end)
            context.stroke()
        }
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

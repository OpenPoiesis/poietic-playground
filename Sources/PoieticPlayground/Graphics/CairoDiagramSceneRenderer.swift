//
//  CairoDiagramSceneRenderer.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 12/07/2026.
//

import PoieticCore
import Diagramming

// FIXME: REFACTORING NOTES (Following comments)
// FIXME: [REFACTORING] How to handle overlays? in DiagramCanvas.drawOverlays
// FIXME: [REFACTORING] How to handle style modifiers?

class CairoDiagramSceneRenderer: DiagramSceneRenderer {
    typealias Context = CairoDrawingContext

    // TODO: [REFACTORING] Use style in a similar way as SVGDiagramStyle, we are reusing old style class for now
    let style: CanvasStyle
    
    init(style: CanvasStyle) {
        self.style = style
    }
    
    func renderBlock(_ entity: RuntimeEntity, context: Context) {
        // TODO: [REFACTORING] Split into overlays
        guard context.overlay == .main else { return }

        // TODO: [REFACTORING] Separate pictogram rendering into renderPictogram(...)
        guard let pictogramNode: RuntimeEntity = entity.target(CanvasNode.Pictogram.self),
              let pictComp: PictogramCanvasNode = pictogramNode.component()
        else { return }

        let pictogram = pictComp.pictogram

//            context.setColor(style.pictogramMaskColor)
//            context.fillPath(pictogram.mask, transform: blockTrans)
        
        let shapeStyle = style.style(class: .pictogram)

        context.setColor(shapeStyle?.stroke ?? CanvasStyle.DefaultStrokeColor)
        context.strokePath(pictogram.path)

        // Highlights
        if let nodeStyle: CanvasNodeStyle = entity.component() {
            // Assumption: Style colours are transparent, therefore we can draw them on top of each other
            if nodeStyle.modifiers.contains(.selected) {
                let shapeStyle = style.style(class: .selection)
                context.setColor(shapeStyle?.stroke ?? CanvasStyle.DefaultFillColor)
                context.fillPath(pictogram.mask)
                context.setColor(shapeStyle?.stroke ?? CanvasStyle.DefaultStrokeColor)
                context.strokePath(pictogram.mask)
            }
            if nodeStyle.modifiers.contains(.allowed) {
                context.setColor(style.acceptingColor)
                context.fillPath(pictogram.mask)
                context.setColor(style.selectionOutlineColor)
                context.strokePath(pictogram.mask)
            }
            else if nodeStyle.modifiers.contains(.notAllowed) {
                context.setColor(style.notAllowedColor)
                context.fillPath(pictogram.mask)
                context.setColor(style.selectionOutlineColor)
                context.strokePath(pictogram.mask)
            }
        }
    }

    func renderConnector(_ entity: RuntimeEntity, context: Context) {
        guard context.overlay == .main else { return }

        guard let stroke: ConnectorStroke = entity.component()
        else { return }

        // Open curves
        context.setLineWidth(style.defaultConnectorLineWidth)
        context.setColor(style.defaultConnectorColor)
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
            context.setColor(style.defaultConnectorFillColor)
            context.addPath(path)
            context.fill()
        }

        if let nodeStyle: CanvasNodeStyle = entity.component(),
           let wire: ConnectorWire = entity.component()
        {
            // Assumption: Style colours are transparent, therefore we can draw them on top of each other
            if nodeStyle.modifiers.contains(.selected) {
                let wirePath = BezierPath(polyline: wire.points)
                context.save()
                context.setColor(Color(red: 1.0, green: 0.8, blue: 0.0))
                context.setLineWidth(4)
                context.strokePath(wirePath)

                context.setColor(style.selectionFillColor)
                // TODO: [REFACTORING] Precompute this on connector as ConnectorOutline
                let outline = wirePath.inflated(by: 10.0)
                context.fillPath(outline)

                context.restore()
            }
        }

    }
    func renderPictogram(_ entity: RuntimeEntity, context: Context) {
        guard context.overlay == .main else { return }
        debugPrint("WARNING: \(#function) not implemented")
    }
    func renderLabel(_ entity: RuntimeEntity, context: Context) {
        guard context.overlay == .main else { return }

        guard let label: LabelCanvasNode = entity.component()
        else { return }
        let styleClass: StyleClass
        if let nodeStyle: CanvasNodeStyle = entity.component() {
            styleClass = nodeStyle.class
        }
        else {
            styleClass = .label
        }
        // FIXME: [REFACTORING] Use styleclass

        context.setFontSize(style.primaryLabelStyle.fontSize)
        context.setColor(style.primaryLabelStyle.color)
        context.showText(label.text, at: .zero)
    }
    func renderValueIndicator(_ entity: RuntimeEntity, context: Context) {
        guard context.overlay == .indicator else { return }
        debugPrint("WARNING: \(#function) not implemented")
    }
    func renderIssueIndicator(_ entity: RuntimeEntity, context: Context) {
        guard context.overlay == .indicator else { return }
        debugPrint("WARNING: \(#function) not implemented")
    }
    func renderColorSwatch(_ entity: RuntimeEntity, context: Context) {
        guard let swatch: ColorSwatchCanvasNode = entity.component()
        else { return }

        debugPrint("WARNING: \(#function) not implemented")
    }
}

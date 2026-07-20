//
//  CairoLayoutProvider.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 13/07/2026.
//

import Ccairo
import Diagramming

struct CairoLayoutProvider: LayoutProvider {
    private let context: OpaquePointer
    let style: CanvasStyle
    
    init(context: OpaquePointer, style: CanvasStyle) {
        self.context = context
        self.style = style
    }

    func metric(_ metric: DiagramLayoutMetric, default defaultValue: Double) -> Double {
        style.metric(metric, default: defaultValue)
    }

    func textExtents(_ text: String, class styleClass: StyleClass) -> Rect2D {
        let labelStyle = style.labelStyle(class: styleClass)
        let fontFamily = labelStyle?.family ?? "Sans"
        let fontSize = labelStyle?.size ?? CanvasStyle.DefaultFontSize
        
        cairo_save(context)
        cairo_select_font_face(context, fontFamily,
            CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_NORMAL)
        cairo_set_font_size(context, fontSize)
        var ext = cairo_text_extents_t()
        cairo_text_extents(context, text, &ext)
        cairo_restore(context)
        
        return Rect2D(origin: .zero, size: Vector2D(ext.width, ext.height))
    }
}

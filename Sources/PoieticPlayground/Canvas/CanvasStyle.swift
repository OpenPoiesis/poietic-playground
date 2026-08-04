//
//  CanvasStyle.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 06/02/2026.
//

import PoieticCore
import Diagramming

struct LabelStyle {
    let family: String
    let size: Double
    // Not yet used
    let weight: Int
    // Not yet used
    let slant: FontSlant
    let color: Color?
    init(family: String,
         size: Double = CanvasStyle.DefaultFontSize,
         weight: Int = 100,
         slant: FontSlant = .normal,
         color: Color? = nil)
    {
        self.family = family
        self.size = size
        self.weight = weight
        self.slant = slant
        self.color = color
    }
}
enum FontSlant {
    case normal
    case italic
    case oblique
}

struct ShapeStyle: Component, Sendable {
    let stroke: Color?
    let fill: Color?
    let lineWidth: Double

    internal init(stroke: Color? = nil, fill: Color? = nil, lineWidth: Double = 1.0) {
        self.stroke = stroke
        self.fill = fill
        self.lineWidth = lineWidth
    }
}

let WarmCharcoalColor = Color(red: 0.22, green: 0.20, blue: 0.18)
let WarmSlateBlueColor = Color(red: 0.25, green: 0.35, blue: 0.55)
let ErrorRedColor = Color(red: 0.85, green: 0.18, blue: 0.12)


final class CanvasStyle: Sendable {
    public static let DefaultCanvasColor = Color(red: 0.97, green: 0.96, blue: 0.93)
    public static let DefaultStrokeColor: Color = .black
    public static let DefaultLabelColor: Color = .black
    public static let DefaultFillColor: Color = .white
    
    public static let DefaultIssueIndicatorStyle = ShapeStyle(stroke: .white, fill: ErrorRedColor)
    public static let DefaultValueIndicatorStyle = ShapeStyle(stroke: .black, fill: .white)
    public static let DefaultIndicatorNormalStyle: ShapeStyle = ShapeStyle(stroke: nil, fill: Color(red:0.22, green:0.62, blue:0.48))
    /// If set, then the style is used to draw the value when the value is less than origin.
    public static let DefaultIndicatorNegativeStyle: ShapeStyle = ShapeStyle(stroke: nil, fill: Color(red: 0.85, green: 0.55, blue: 0.10))
    /// Value used to draw the indicator when the value is greater than max value.
    public static let DefaultIndicatorOverflowStyle: ShapeStyle = ShapeStyle(stroke: nil, fill: Color(red: 0.80, green: 0.22, blue: 0.10))
    /// Value used to draw the indicator when the value is less than min value.
    public static let DefaultIndicatorUnderflowStyle: ShapeStyle = ShapeStyle(stroke: nil, fill: Color(red:0.25, green:0.48, blue:0.72))
    /// Style of the indicator when the value is not set.
    public static let DefaultIndicatorEmptyStyle: ShapeStyle = ShapeStyle(stroke: nil, fill: Color(red: 0.72, green: 0.70, blue: 0.67))

    struct Key: Hashable {
        let `class`: StyleClass
        let modifiers: StyleModifierSet
        init(_ styleClass: StyleClass, modifiers: StyleModifierSet = []) {
            self.class = styleClass
            self.modifiers = modifiers
        }
    }
    
    // TODO: [REFACTORING] [IMPORTANT] Add styles with modifiers, especially for indicator normal, negative, overflow, underflow and empty
    public static let DefaultFontSize: Double = 11.0

    public static let Default = CanvasStyle(
        shapeStyles: [
            Key(.normal): ShapeStyle(stroke: .black, fill: .white, lineWidth: 1.0),
            // Canvas background
            Key(.canvas): ShapeStyle(fill: Color(red: 0.97, green: 0.96, blue: 0.93)),
            Key(.grid): ShapeStyle(stroke: Color(red: 0.3, green: 0.3, blue: 0.3, alpha: 0.2)),
            Key(.highlight, modifiers: .selected): ShapeStyle(stroke: Color(red: 0.25, green: 0.50, blue: 0.85), fill: Color(red: 0.35, green: 0.60, blue: 0.90, alpha: 0.18)),
            Key(.highlight, modifiers: .allowed): ShapeStyle(stroke: Color(red: 0.18, green: 0.68, blue: 0.40), fill: Color.screenGreen.withTransparency(0.2)),
            Key(.highlight, modifiers: .notAllowed): ShapeStyle(stroke: Color(red: 0.88, green: 0.28, blue: 0.15), fill: Color.screenRed.withTransparency(0.2)),
            Key(.handle): ShapeStyle(stroke: Color(red: 0.90, green: 0.65, blue: 0.20)),
            Key(.issueIndicator): ShapeStyle(stroke: .white, fill: ErrorRedColor),

            Key(.valueIndicator): ShapeStyle(stroke: .black, fill: .white),
            Key(.valueIndicator, modifiers: .positive): ShapeStyle(stroke: nil, fill: Color(red:0.22, green:0.62, blue:0.48)),
            Key(.valueIndicator, modifiers: .negative): ShapeStyle(stroke: nil, fill: Color(red: 0.85, green: 0.55, blue: 0.10)),
            Key(.valueIndicator, modifiers: .overflow): ShapeStyle(stroke: nil, fill: Color(red: 0.80, green: 0.22, blue: 0.10)),
            Key(.valueIndicator, modifiers: .underflow): ShapeStyle(stroke: nil, fill: Color(red:0.25, green:0.48, blue:0.72)),
            Key(.valueIndicator, modifiers: .empty): ShapeStyle(stroke: nil, fill: Color(red: 0.72, green: 0.70, blue: 0.67)),
            Key(.valueIndicatorLine): ShapeStyle(stroke: .black),

            // Content
            Key(.pictogram):ShapeStyle(stroke: WarmSlateBlueColor),
            
            Key(.thinConnector):ShapeStyle(stroke: WarmSlateBlueColor),
            Key(.fatConnector):ShapeStyle(stroke: WarmSlateBlueColor, fill: WarmSlateBlueColor.withTransparency(0.5)),

            // Labels
            Key(.primaryLabel): ShapeStyle(stroke: Color(red: 0.22, green: 0.20, blue: 0.18)),

            // Previews and intents
//            Key(.block, modifiers: .preview): ShapeStyle(stroke: .screenBlue, fill: .screenYellow, lineWidth: 1.0),
            Key(.block, modifiers: .preview): ShapeStyle(stroke: Color(red: 0.25, green: 0.35, blue: 0.55, alpha: 0.3)),
        ],
        labelStyles: [
            Key(.label):LabelStyle(family: "IBM Plex Sans", size: 11.0, color: .black),
            Key(.primaryLabel):LabelStyle(family: "IBM Plex Sans", size: 12.0, color: Color(red: 0.22, green: 0.20, blue: 0.18)),
            Key(.secondaryLabel):LabelStyle(family: "IBM Plex Sans", size: 11.0, slant: .italic, color: .screenBlue),
            Key(.valueIndicator):LabelStyle(family: "IBM Plex Sans", size: 11.0, color: Color(gray: 0.5)),
            // TODO: Invalid label style with color .screenRed
        ],
        metrics: [
            .colorSwatchSize: 10.0,
            .primaryLabelPadding: 10.0,
            .secondaryLabelPadding: 16.0,
            .handleSize: 10.0,
            .valueIndicatorPadding: 10.0,
        ]
    )

    public let shapeStyles: [Key:ShapeStyle]
    public let labelStyles: [Key:LabelStyle]
    public let metrics: [DiagramLayoutMetric:Double]
    public let adaptableColors: [AdaptableColorKey:Color]
        
    public init(shapeStyles: [Key:ShapeStyle],
                labelStyles: [Key:LabelStyle],
                adaptableColors: [AdaptableColorKey:Color] = [:],
                metrics: [DiagramLayoutMetric:Double] = [:]) {
        self.shapeStyles = shapeStyles
        self.labelStyles = labelStyles
        self.adaptableColors = adaptableColors
        self.metrics = metrics
    }
    
    /// Get shape style for given style class and style modifiers.
    ///
    /// If modi
    func shapeStyle(class styleClass: StyleClass, modifiers: StyleModifierSet = []) -> ShapeStyle? {
        let exact = Key(styleClass, modifiers: modifiers)
        if let style = shapeStyles[exact] {
            return style
        }
        else {
            return shapeStyles[Key(styleClass)]
        }
    }
    func shapeStyle(_ nodeStyle: CanvasNodeStyle) -> ShapeStyle? {
        return shapeStyle(class: nodeStyle.class, modifiers: nodeStyle.modifiers)
    }

    func labelStyle(class styleClass: StyleClass, modifiers: StyleModifierSet = []) -> LabelStyle? {
        let exact = Key(styleClass, modifiers: modifiers)
        if let style = labelStyles[exact] {
            return style
        }
        else {
            return labelStyles[Key(styleClass)]
        }
    }
    
    func adaptableColor(_ key: AdaptableColorKey, default defaultColor: Color) -> Color {
        return adaptableColors[key, default: defaultColor]
    }
    
    public func metric(_ metric: DiagramLayoutMetric, default defaultValue: Double) -> Double {
        return metrics[metric] ?? defaultValue
    }
}

#if false
class _OLDCanvasStyle {
//    var errorIndicatorBackground: Color = Color.white.withTransparency(0.5)
//    var errorIndicatorColor: Color = Color(red: 0.7, green: 0.2, blue: 0.2)

    // Indicator
    /// Style used to draw the indicator background, before the actual indicator content.
    /// Style used to draw the indicator bar when the value is within bounds and when the negative
    /// style is not set.
    var indicatorNormalStyle: ShapeStyle = ShapeStyle(outline: nil, fill: Color(red:0.22, green:0.62, blue:0.48))
    /// If set, then the style is used to draw the value when the value is less than origin.
    var indicatorNegativeStyle: ShapeStyle = ShapeStyle(outline: nil, fill: Color(red: 0.85, green: 0.55, blue: 0.10))
    /// Value used to draw the indicator when the value is greater than max value.
    var indicatorOverflowStyle: ShapeStyle = ShapeStyle(outline: nil, fill: Color(red: 0.80, green: 0.22, blue: 0.10))
    /// Value used to draw the indicator when the value is less than min value.
    var indicatorUnderflowStyle: ShapeStyle = ShapeStyle(outline: nil, fill: Color(red:0.25, green:0.48, blue:0.72))
    /// Style of the indicator when the value is not set.
    var indicatorEmptyStyle: ShapeStyle = ShapeStyle(outline: nil, fill: Color(red: 0.72, green: 0.70, blue: 0.67))

    init() { /* Empty init */ }
    
    func adaptableColor(_ key: AdaptableColorKey, default defaultColor: Color) -> Color {
        return adaptableColors[key, default: defaultColor]
    }
    func lineWidth(_ name: String, defaultWidth: Float = 1.0) -> Float {
        return lineWidths[name, default: defaultWidth]
    }
    
}
#endif

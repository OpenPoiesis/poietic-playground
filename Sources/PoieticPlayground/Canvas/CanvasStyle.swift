//
//  CanvasStyle.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 06/02/2026.
//

import PoieticCore
import Diagramming

class CanvasStyleCatalog {
    struct Entry {
        let name: String
        let path: String
    }
    var entries: [Entry]
    
    init(_ entries: [Entry]) {
        self.entries = entries
    }

    func path(forNotationNamed name: String) -> String? {
        guard let entry = entries.first(where: { $0.name == name })
        else { return nil }
        return entry.path
    }

}

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
    
    public static let DefaultFontSize: Double = 11.0


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

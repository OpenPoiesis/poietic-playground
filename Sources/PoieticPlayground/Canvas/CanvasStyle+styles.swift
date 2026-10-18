//
//  CanvasStyle+light.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 14/10/2026.
//

// TODO: Make several built-in styles (see below)
// Built-in styles:
//      - Light: warm paper and warm blue ink
//      - Dark: warm deep brown canvas with warm light ink
//      - OldSchool (light): white canvas, red connectors, blue blocks
//      - AmberTerminal (dark)
//      - Monochrome-Grayscale White(light)/Black(dark)


enum DefaultColors {
    // Paper surfaces, from the sheet to the shadow it casts
    static let Parchment = Color(red: 0.949, green: 0.929, blue: 0.886)  // #F2EDE2
    static let Cream     = Color(red: 0.984, green: 0.973, blue: 0.945)  // #FBF8F1
    static let Bone      = Color(red: 0.729, green: 0.706, blue: 0.659)  // #BAB4A8
    static let Chalk     = Color(red: 0.918, green: 0.894, blue: 0.855)  // #EAE4DA
    static let Graphite  = Color(red: 0.290, green: 0.278, blue: 0.263)  // #4A4743
    static let Slate     = Color(red: 0.412, green: 0.396, blue: 0.373)  // #69655F

    // Ink and chalk
    static let Ink   = Color(red: 0.157, green: 0.137, blue: 0.118)  // #28231E
    static let Umber = Color(red: 0.400, green: 0.376, blue: 0.349)  // #666059
    static let Soot  = Color(red: 0.082, green: 0.075, blue: 0.067)  // #151311

    // Pigments
    static let Cobalt     = Color(red: 0.180, green: 0.310, blue: 0.592)  // #2E4F97
    static let Cerulean   = Color(red: 0.322, green: 0.451, blue: 0.682)  // #5273AE
    static let Prussian   = Color(red: 0.114, green: 0.212, blue: 0.325)  // #1D3653
    static let Moss       = Color(red: 0.239, green: 0.353, blue: 0.196)  // #3D5A32
    static let Fern       = Color(red: 0.361, green: 0.533, blue: 0.310)  // #5C884F
    static let Verdigris  = Color(red: 0.263, green: 0.502, blue: 0.443)  // #438071
    static let Brass      = Color(red: 0.769, green: 0.573, blue: 0.271)  // #C49245
    static let Amber      = Color(red: 0.882, green: 0.639, blue: 0.243)  // #E1A33E
    static let Ochre      = Color(red: 0.545, green: 0.400, blue: 0.157)  // #8B6628
    static let Rust       = Color(red: 0.647, green: 0.310, blue: 0.157)  // #A54F28
    static let Vermilion  = Color(red: 0.788, green: 0.263, blue: 0.157)  // #C94328
}

extension CanvasStyle {
    public static let Default = CanvasStyle.Light
    public static let Light = CanvasStyle.NewLight
    public static let Dark = CanvasStyle.NewDark
    public static let OldLight = CanvasStyle(
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
            .primaryLabelPadding: 2.0,
            .secondaryLabelPadding: 4.0,
            .handleSize: 10.0,
            .valueIndicatorPadding: 10.0,
        ]
    )

    public static let OldDark = CanvasStyle(
        shapeStyles: [
            Key(.normal): ShapeStyle(stroke: .white, fill: .black, lineWidth: 1.0),
            Key(.canvas): ShapeStyle(fill: Color(red: 0.03, green: 0.04, blue: 0.07)),
            Key(.grid): ShapeStyle(stroke: Color(red: 0.7, green: 0.7, blue: 0.7, alpha: 0.2)),
            Key(.highlight, modifiers: .selected): ShapeStyle(stroke: Color(red: 0.25, green: 0.50, blue: 0.85), fill: Color(red: 0.35, green: 0.60, blue: 0.90, alpha: 0.18)),
            Key(.highlight, modifiers: .allowed): ShapeStyle(stroke: Color(red: 0.18, green: 0.68, blue: 0.40), fill: Color.screenGreen.withTransparency(0.2)),
            Key(.highlight, modifiers: .notAllowed): ShapeStyle(stroke: Color(red: 0.88, green: 0.28, blue: 0.15), fill: Color.screenRed.withTransparency(0.2)),
            Key(.handle): ShapeStyle(stroke: Color(red: 0.90, green: 0.65, blue: 0.20)),
            Key(.issueIndicator): ShapeStyle(stroke: .white, fill: ErrorRedColor),

            Key(.valueIndicator): ShapeStyle(stroke: .white, fill: .black),
            Key(.valueIndicator, modifiers: .positive): ShapeStyle(stroke: nil, fill: Color(red:0.22, green:0.62, blue:0.48)),
            Key(.valueIndicator, modifiers: .negative): ShapeStyle(stroke: nil, fill: Color(red: 0.85, green: 0.55, blue: 0.10)),
            Key(.valueIndicator, modifiers: .overflow): ShapeStyle(stroke: nil, fill: Color(red: 0.80, green: 0.22, blue: 0.10)),
            Key(.valueIndicator, modifiers: .underflow): ShapeStyle(stroke: nil, fill: Color(red:0.25, green:0.48, blue:0.72)),
            Key(.valueIndicator, modifiers: .empty): ShapeStyle(stroke: nil, fill: Color(red: 0.72, green: 0.70, blue: 0.67)),
            Key(.valueIndicatorLine): ShapeStyle(stroke: .white),

            // Content
            Key(.block):ShapeStyle(stroke: Color.white),
            Key(.pictogram):ShapeStyle(stroke: Color.white),

            Key(.thinConnector):ShapeStyle(stroke: Color.screenYellow),
            Key(.fatConnector):ShapeStyle(stroke: Color.screenYellow, fill: WarmSlateBlueColor.withTransparency(0.5)),

            // Labels
            Key(.primaryLabel): ShapeStyle(stroke: Color(red: 0.78, green: 0.80, blue: 0.82)),

            // Previews and intents
//            Key(.block, modifiers: .preview): ShapeStyle(stroke: .screenBlue, fill: .screenYellow, lineWidth: 1.0),
            Key(.block, modifiers: .preview): ShapeStyle(stroke: Color(red: 0.25, green: 0.35, blue: 0.55, alpha: 0.3)),
        ],
        labelStyles: [
            Key(.label):LabelStyle(family: "IBM Plex Sans", size: 11.0, color: .white),
            Key(.primaryLabel):LabelStyle(family: "IBM Plex Sans", size: 12.0, color: Color(red: 0.78, green: 0.80, blue: 0.82)),
            Key(.secondaryLabel):LabelStyle(family: "IBM Plex Sans", size: 11.0, slant: .italic, color: .screenCyan),
            Key(.valueIndicator):LabelStyle(family: "IBM Plex Sans", size: 11.0, color: Color(gray: 0.5)),
            // TODO: Invalid label style with color .screenRed
        ],
        metrics: [
            .colorSwatchSize: 10.0,
            .primaryLabelPadding: 2.0,
            .secondaryLabelPadding: 4.0,
            .handleSize: 10.0,
            .valueIndicatorPadding: 10.0,
        ]
    )

    // MARK: - New styles
    
    public static let NewLight = CanvasStyle(
        shapeStyles: [
            // Default stroke, used for anything not styled otherwise.
            Key(.normal): ShapeStyle(stroke: DefaultColors.Ink,
                                     fill: DefaultColors.Cream,
                                     lineWidth: 1.0),

            Key(.canvas): ShapeStyle(fill: DefaultColors.Parchment),
            Key(.grid): ShapeStyle(stroke: DefaultColors.Graphite.withTransparency(0.45),
                                   lineWidth: 0.5),

            Key(.highlight, modifiers: .selected): ShapeStyle(stroke: DefaultColors.Cobalt,
                                                              fill: DefaultColors.Cobalt.withTransparency(0.18)),
            Key(.highlight, modifiers: .allowed): ShapeStyle(stroke: DefaultColors.Moss,
                                                             fill: DefaultColors.Moss.withTransparency(0.18)),
            Key(.highlight, modifiers: .notAllowed): ShapeStyle(stroke: DefaultColors.Vermilion,
                                                                fill: DefaultColors.Vermilion.withTransparency(0.18)),
            Key(.handle): ShapeStyle(stroke: DefaultColors.Brass, lineWidth: 1.0),
            Key(.issueIndicator): ShapeStyle(stroke: DefaultColors.Parchment, fill: DefaultColors.Vermilion),


            Key(.valueIndicator): ShapeStyle(stroke: DefaultColors.Umber, fill: DefaultColors.Cream),

            Key(.valueIndicator, modifiers: .positive): ShapeStyle(stroke: nil, fill: DefaultColors.Verdigris),
            Key(.valueIndicator, modifiers: .negative): ShapeStyle(stroke: nil, fill: DefaultColors.Brass),
            Key(.valueIndicator, modifiers: .overflow): ShapeStyle(stroke: nil, fill: DefaultColors.Vermilion),
            Key(.valueIndicator, modifiers: .underflow): ShapeStyle(stroke: nil, fill: DefaultColors.Cerulean),
            Key(.valueIndicator, modifiers: .empty): ShapeStyle(stroke: nil, fill: DefaultColors.Bone),
            Key(.valueIndicatorLine): ShapeStyle(stroke: DefaultColors.Ink, lineWidth: 1.0),

            // Content

            Key(.block): ShapeStyle(stroke: DefaultColors.Ink, fill: DefaultColors.Cream),
            Key(.pictogram): ShapeStyle(stroke: DefaultColors.Prussian),

            Key(.fatConnector): ShapeStyle(stroke: DefaultColors.Prussian,
                                           fill: DefaultColors.Prussian.withTransparency(0.18),
                                           lineWidth: 1.0),
            Key(.thinConnector): ShapeStyle(stroke: DefaultColors.Umber, lineWidth: 0.9),

            Key(.primaryLabel): ShapeStyle(stroke: DefaultColors.Ink),

            Key(.block, modifiers: .preview): ShapeStyle(stroke: DefaultColors.Cobalt.withTransparency(0.30),
                                                         fill: DefaultColors.Cream.withTransparency(0.50)),
        ],
        labelStyles: [
            Key(.label): LabelStyle(family: "IBM Plex Sans", size: 11.0,
                                    color: DefaultColors.Ink),
            Key(.primaryLabel): LabelStyle(family: "IBM Plex Sans", size: 12.0,
                                           color: DefaultColors.Ink),
            Key(.secondaryLabel): LabelStyle(family: "IBM Plex Sans", size: 11.0, slant: .italic,
                                             color: DefaultColors.Cerulean),
            Key(.valueIndicator): LabelStyle(family: "IBM Plex Sans", size: 11.0,
                                             color: DefaultColors.Ink),
            // TODO: Invalid label style with a vermilion colour
        ],
        metrics: [
            .colorSwatchSize: 10.0,
            .primaryLabelPadding: 2.0,
            .secondaryLabelPadding: 4.0,
            .handleSize: 10.0,
            .valueIndicatorPadding: 10.0,
        ]
    )

    public static let NewDark = CanvasStyle(
        shapeStyles: [
            Key(.normal): ShapeStyle(stroke: DefaultColors.Chalk,
                                     fill: DefaultColors.Slate.darkened(0.45),
                                     lineWidth: 1.0),

            Key(.canvas): ShapeStyle(fill: DefaultColors.Soot),
            Key(.grid): ShapeStyle(stroke: DefaultColors.Bone.withTransparency(0.20),
                                   lineWidth: 0.5),

            Key(.highlight, modifiers: .selected): ShapeStyle(stroke: DefaultColors.Cerulean,
                                                              fill: DefaultColors.Cerulean.withTransparency(0.22)),
            Key(.highlight, modifiers: .allowed): ShapeStyle(stroke: DefaultColors.Fern,
                                                             fill: DefaultColors.Fern.withTransparency(0.22)),
            Key(.highlight, modifiers: .notAllowed): ShapeStyle(stroke: DefaultColors.Rust,
                                                                fill: DefaultColors.Rust.withTransparency(0.22)),
            Key(.handle): ShapeStyle(stroke: DefaultColors.Amber, lineWidth: 1.0),
            Key(.issueIndicator): ShapeStyle(stroke: DefaultColors.Soot, fill: DefaultColors.Vermilion),

            Key(.valueIndicator): ShapeStyle(stroke: DefaultColors.Slate, fill: DefaultColors.Slate.darkened(0.45)),

            Key(.valueIndicator, modifiers: .positive): ShapeStyle(stroke: nil, fill: DefaultColors.Fern),
            Key(.valueIndicator, modifiers: .negative): ShapeStyle(stroke: nil, fill: DefaultColors.Amber),
            Key(.valueIndicator, modifiers: .overflow): ShapeStyle(stroke: nil, fill: DefaultColors.Vermilion),
            Key(.valueIndicator, modifiers: .underflow): ShapeStyle(stroke: nil, fill: DefaultColors.Cerulean),
            Key(.valueIndicator, modifiers: .empty): ShapeStyle(stroke: nil, fill: DefaultColors.Slate),
            Key(.valueIndicatorLine): ShapeStyle(stroke: DefaultColors.Chalk, lineWidth: 1.0),

            // Content
            Key(.block): ShapeStyle(stroke: DefaultColors.Chalk, fill: DefaultColors.Slate.darkened(0.45)),
            Key(.pictogram): ShapeStyle(stroke: DefaultColors.Chalk),

            Key(.thinConnector): ShapeStyle(stroke: DefaultColors.Bone.withTransparency(0.55),
                                            lineWidth: 1.0),
            Key(.fatConnector): ShapeStyle(stroke: DefaultColors.Chalk,
                                           fill: DefaultColors.Slate,
                                           lineWidth: 1.0),

            Key(.primaryLabel): ShapeStyle(stroke: DefaultColors.Chalk),

            Key(.block, modifiers: .preview): ShapeStyle(stroke: DefaultColors.Cerulean.withTransparency(0.30),
                                                         fill: DefaultColors.Slate.withTransparency(0.50)),
        ],
        labelStyles: [
            Key(.label): LabelStyle(family: "IBM Plex Sans", size: 11.0,
                                    color: DefaultColors.Chalk),
            Key(.primaryLabel): LabelStyle(family: "IBM Plex Sans", size: 12.0,
                                           color: DefaultColors.Chalk),
            Key(.secondaryLabel): LabelStyle(family: "IBM Plex Sans", size: 11.0, slant: .italic,
                                             color: DefaultColors.Cerulean),
            Key(.valueIndicator): LabelStyle(family: "IBM Plex Sans", size: 11.0,
                                             color: DefaultColors.Chalk),
            // TODO: Invalid label style with a vermilion colour
        ],
        metrics: [
            .colorSwatchSize: 10.0,
            .primaryLabelPadding: 2.0,
            .secondaryLabelPadding: 4.0,
            .handleSize: 10.0,
            .valueIndicatorPadding: 10.0,
        ]
    )

}

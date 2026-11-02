//
//  DocumentFileCommands.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 04/02/2026.
//

import Foundation
import PoieticCore
import PoieticFlows
import Diagramming

let DefaultDesignPath = "Unnamed.poietic"

class ExportSVGCommand: Command {
    static let FileExtension = "svg"
    var name: String { "export-svg" }
    let url: URL
    
    init(url: URL, appendExtensionIfNeeded: Bool = false) {
        if appendExtensionIfNeeded,
           url.pathExtension.isEmpty || url.pathExtension != Self.FileExtension
        {
            self.url = url.appendingPathExtension(Self.FileExtension)
        }
        else {
            self.url = url
        }
    }
    
    func run(_ context: CommandContext) throws (CommandError) {
        let document = context.document
        let world = document.world
        
        guard let diagram = document.mainDiagram else {
            throw CommandError("No main diagram found", kind: .internal)
        }
        
        let builder = PresentationBuilder(world: world)
        let presentation = builder.createPresentation(diagram: diagram)
        // TODO: Make user pick a SVG style
        let style = SVGDiagramStyle.Default
        presentation.setComponent(LayoutEnvironment(provider: style))

        do {
            try PresentationUpdateSystem.update(world)
        }
        catch {
            throw CommandError(String(describing: error), underlyingError: error)
        }

        let renderer = SVGDiagramRenderer(world: world)

        do {
            try renderer.render(presentation, style: style, to: url.path())
        }
        catch {
            throw CommandError(String(describing: error), underlyingError: error)
        }
    }
}

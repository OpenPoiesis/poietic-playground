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

class NewDesignCommand: WorkspaceCommand {
    var name: String { "new-design" }

    func run(_ context: WorkspaceCommandContext) throws (CommandError) {
        context.app.newDesign()
    }
}

class OpenDesignCommand: WorkspaceCommand {
    var name: String { "open-design" }
    let url: URL
    init(url: URL) {
        self.url = url
    }
    func run(_ context: WorkspaceCommandContext) throws (CommandError) {
        do {
            try context.workspace?.openDesign(url: url)
        }
        catch {
            throw CommandError(String(describing: error), underlyingError: error)
        }
    }
}

class SaveDesignCommand: WorkspaceCommand {
    var name: String { "save-design" }
    let url: URL?
    init(url: URL? = nil, appendExtensionIfNeeded: Bool = false) {
        if appendExtensionIfNeeded, let url {
            self.url = Document.normalizePathExtension(url)
        }
        else {
            self.url = url
        }
    }
    func run(_ context: WorkspaceCommandContext) throws (CommandError) {
        guard let targetURL = url ?? context.document?.designURL else {
            throw CommandError("Save design: No URL provided", severity: .error)
        }
        
        do {
            try context.document?.save(to: targetURL)
        }
        catch {
            throw CommandError(String(describing: error), underlyingError: error)
        }
    }
}

class ExportSVGCommand: WorkspaceCommand {
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
    
    func run(_ context: WorkspaceCommandContext) throws (CommandError) {
        guard let diagram = context.document.mainDiagram else {
            throw CommandError("No main diagram found", severity: .fatal)
        }
        
        let composer = DiagramSceneComposer(world: context.world)
        let scene = composer.createScene(diagram: diagram)
        // TODO: Make user pick a SVG style
        let style = SVGDiagramStyle.Default
        scene.setComponent(SceneLayoutProvider(provider: style))

        do {
            try SceneCompositionSystem.update(context.world)
        }
        catch {
            throw CommandError(String(describing: error), underlyingError: error)
        }

        let renderer = SVGDiagramSceneRenderer(world: context.world)

        do {
            try renderer.render(scene, style: style, to: url.path())
        }
        catch {
            throw CommandError(String(describing: error), underlyingError: error)
        }
    }
}

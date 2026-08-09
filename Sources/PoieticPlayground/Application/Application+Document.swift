//
//  Application+Session.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 05/03/2026.
//

import Foundation
import PoieticCore

extension Application {
    /// Set a new design document and propagate the change through the application.
    ///
    func newDocument(_ design: Design, designURL: URL? = nil) {
        if let designURL {
            self.log("Design URL: \(designURL.standardizedFileURL)")
        }
        
        let document = Document(design: design, url: designURL, notation: notation)
        document.needsWorldFrameUpdate = true

        self.document = document
        bindToDocument(document)
    }
    
    func connectObservers(_ document: Document) {
        document.addObserver(inspector.onSelectionChanged, on: .designFrameChanged)
        document.addObserver(inspector.onSelectionChanged, on: .selectionChanged)
        document.addObserver(inspector.onSimulationFinished, on: .simulationFinished)
        document.addObserver(canvas.onDesignFrameChanged, on: .designFrameChanged)
        document.addObserver(canvas.onSelectionChanged, on: .selectionChanged)
        document.addObserver(canvas.onSimulationPlayerStep, on: .simulationPlayerStep)
        document.addObserver(canvas.onSimulationPlayerStep, on: .simulationFinished)

        document.addObserver(canvas.onInteractivePreviewChanged, on: .previewChanged)
        document.addObserver(canvas.onPreviewStarted, on: .previewStarted)
        document.addObserver(canvas.onPreviewEnded, on: .previewEnded)

        document.addObserver(controlBar.onDesignFrameChanged, on: .designFrameChanged)
        document.addObserver(controlBar.onSimulationPlayerStep, on: .simulationPlayerStep)
        document.addObserver(player.onDesignFrameChanged, on: .designFrameChanged)
        document.addObserver(player.onSimulationFailed, on: .simulationFailed)
        document.addObserver(dashboard.onDesignFrameChanged, on: .designFrameChanged)

        document.addObserver(graphicFunctionPanel.onSelectionChanged, on: .selectionChanged)

        document.addObserver(debugDesignPanel.onSelectionChanged, on: .selectionChanged)
    }
    
    func bindToDocument(_ document: Document) {
        document.removeAllObservers()

        canvas.bind(document)
        inspector.bind(document)
        issuesPanel.bind(document)
        player.bind(document)
        dashboard.bind(document)
        graphicFunctionPanel.bind(document)
        metamodelPanel.bind(document)
        debugDesignPanel.bind(document)
        dataTablePanel.bind(document)

        for tool in canvasTools {
            tool.bind(canvas: canvas, document: document)
        }
        connectObservers(document)
    }
}

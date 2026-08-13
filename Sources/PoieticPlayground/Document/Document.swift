//
//  Session.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 05/02/2026.
//

import PoieticCore
import Foundation
import Diagramming

/// Represents and controls the design document.
///
/// Responsibilities:
/// - Owns Design – the user created content, the model (Design)
/// - Owns World – derived and simulation data
/// - Manages file I/O
/// - Manages transactions, command queue
/// - Selection state
/// - Observer/event system
///
class Document {
    static let FileExtension = "poietic"
    
    /// - SeeAlso: ``Application/connectObservers(_:)``.
    enum Event {
        /// Triggered when world plane has been changed, usually after a transaction or
        /// on undo/redo action.
        ///
        /// Handled by:
        /// - inspector
        /// - canvas
        /// - control bar
        /// - player
        /// - dashboard
        case designPlaneChanged
        
        /// Triggered:
        /// - when selection is changed, through ``Document/changeSelection(_:)
        /// - on plane change
        /// Handled by:
        /// - ``InspectorPanel``
        case selectionChanged

        /// Triggered:
        /// - by selection tool on selection move or handle move
        /// Handled by:
        /// - Canvas
        case previewStarted
        case previewChanged
        /// Triggered:
        /// - when selection move is concluded or cancelled
        /// Handled by:
        /// - Canvas
        case previewEnded

        case simulationFinished
        case simulationFailed

//        case simulationPlayerStarted
        case simulationPlayerStep
//        case simulationPlayerStopped
    }

    typealias EventObserver = ((Document) -> Void)

    var observers: [Event:[EventObserver]]
    
    let design: Design
    var designURL: URL? = nil
    
    var transaction: TransientPlane?
    var hasTransaction: Bool { transaction != nil }
    var commandQueue: [any Command]

    let world: World
    
    /// Flag whether we need to update the world plane on next call to update.
    var needsWorldPlaneUpdate: Bool = false
    
    var selection: Selection
    var selectionOverview: SelectionOverview
    
    
    // Known entities
    var mainDiagram: RuntimeEntity? = nil
    var mainDiagramScene: RuntimeEntity? = nil
    
    /// Flag whether ``InteractivePreviewSchedule`` is run at the end of the update.
    /// The flag is reset each application plane.
    internal private(set) var requiresInteractivePreviewUpdate: Bool
    /// Interactive preview in progress.
    var isPreviewing: Bool
    
    // MARK: - Schedules
    
    
    // MARK: - Initialisation
    
    init(design: Design, url: URL? = nil, notation: Notation? = nil) {
        self.observers = [:]
        
        self.design = design
        self.designURL = url
        self.world = World(design: design)
        self.transaction = nil
        
        self.selection = Selection()
        self.selectionOverview = SelectionOverview()
        self.commandQueue = []

        // Flags
        self.requiresInteractivePreviewUpdate = false
        self.isPreviewing = false
        
        setupWorld(notation: notation)
    }
  
    // MARK: - Observers

    func removeAllObservers() {
        observers.removeAll()
    }
    func addObserver(_ observer: @escaping EventObserver, on event: Event) {
        observers[event, default: []].append(observer)
    }
    
    func trigger(_ event: Event) {
        guard let receivers = self.observers[event] else { return }
        for receiver in receivers {
            receiver(self)
        }
    }
    
    // MARK: - Selection

    func changeSelection(_ change: SelectionChange) {
        selection.apply(change)
        
        updateSelectionOverview()
        trigger(.selectionChanged)
    }
    /// Called on:
    /// - selection changed with ``changeSelection(_:)``
    /// - plane changed with ``Application/accept(_:)``
    func updateSelectionOverview() {
        if self.selection.isEmpty {
            self.selectionOverview.clear()
        }
        if let plane = world.plane {
            self.selectionOverview.update(selection, plane: plane)
        }
        else {
            self.selectionOverview.clear()
        }

        syncSelection()
    }
    func syncSelection() {
        for entity: RuntimeEntity in world.query(IsSelected.self) {
            guard let id = entity.objectID, !selection.contains(id) else { continue }
            entity.removeComponent(IsSelected.self)
        }
        for id in selection {
            guard let entity = world.entity(id), !entity.contains(IsSelected.self) else { continue }
            entity.setComponent(IsSelected())
        }
        world.setSingleton(selection)
    }


    // MARK: - Interactive Preview

    func beginInteractivePreview() {
        self.isPreviewing = true
        self.trigger(.previewStarted)
        self.requiresInteractivePreviewUpdate = true
    }
    
    func queueInteractivePreviewUpdate() {
        self.requiresInteractivePreviewUpdate = true
    }
    func resetInteractivePreviewUpdate() {
        self.requiresInteractivePreviewUpdate = false
    }
    
    func endInteractivePreview() {
        self.isPreviewing = false
        
        world.removeComponentForAll(PreviewPositionComponent.self)
        world.removeComponentForAll(PreviewMidpoints.self)
        self.trigger(.previewEnded)
    }

    func onSimulationPlayerStep(_ document: Document) {
        // TODO: This is weird, as we should be receiving this event only triggered by us.
    }
}


// TODO: Use shared application logger
extension Document {
    func log(_ message: String) {
        print("INFO: ", message)
    }
    func logError(_ message: String) {
        print("ERROR: ", message)
    }
}

// FIXME: Make a proper alert mechanism. This is a quick hack to silence the compiler after refactoring.
extension Document {
    func queueAlert(title: String, message: String) {
        Task { @MainActor in
            await Application.shared.queueAlert(title: title, message: message)
        }
    }
}

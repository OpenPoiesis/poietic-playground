//
//  CanvasTool.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 26/01/2026.
//
import CIimgui
import Diagramming
import PoieticCore

enum CanvasToolType {
    /// No tool
    case empty
    case selection
    case placement
    case connect
    case pan
    
    var name: String {
        switch self {
        case .empty: "empty"
        case .selection: "selection"
        case .placement: "placement"
        case .connect: "connect"
        case .pan: "pan"
        }
    }
}

/// Abstract class for canvas tools.
///
/// Subclasses should implement:
///
/// - Input handling: ``inputBegan(_:in:)``, ``inputMoved(_:in:)``, ``inputEnded(_:in:)``.
/// - Optional activation/deactivation with ``activate()``, ``deactivate()``.
/// - Internal tool state management.
///
/// Tools are authority for interactions and interaction state. They can:
///
/// - Change selection with ``Document/changeSelection(_:)``
/// - Create transactions with ``Document/createOrReuseTransaction()``
/// - Queue commands.
/// - Open and close inline editors.
///
/// Tools can create interactive preview components in the world (``Document/world``) which
/// will be drawn by setting ``Document/requiresInteractivePreviewUpdate`` to ``true``.
///
@MainActor
class CanvasTool {
    enum EngagementResult {
        /// Tool is not concerned about the event, try fallback in tool chain.
        case pass
        /// Tool has processed the event and has finished.
        case consumed
        /// Tool has processed the event and will handle all future events until finished or cancelled.
        case engaged
    }
    
    /// Canvas the tool is bound to.
    ///
    /// Tool is bound to a canvas together with a document using ``bind(canvas:document:)``.
    ///
    /// Functions typically used:
    ///
    /// - ``DiagramCanvas/screenToWorld(_:)->Vector2D``
    /// - ``DiagramCanvas/hitTarget(screenPosition:)``
    /// - ``DiagramCanvas/zoomLevel``
    ///
    weak var canvas: DiagramCanvas?

    /// Document the tool is bound to.
    ///
    /// Tool is bound to a document together with a canvas using ``bind(canvas:document:)``.
    ///
    /// Document properties and functions typically used by a tool:
    ///
    /// - ``Document/selection`` and ``Session/changeSelection(_:)``
    /// - ``Document/createOrReuseTransaction()``
    /// - ``Document/requiresInteractivePreviewUpdate``
    ///
    weak var document: Document?

    internal var world: World {
        guard let document else { fatalError("CanvasTool used before binding")}
        return document.world
    }
    
    var hasObjectPalette: Bool { false }
    var type: CanvasToolType { .empty }
    var iconKey: IconKey { .empty }
    
    /// Called before tool activation.
    func bind(canvas: DiagramCanvas, document: Document) {
        self.document = document
        self.canvas = canvas
    }

    func drawPalette() { }
    
    /// Function called when tool was set active.
    func activate() { /* Implementation in subclasses */ }

    /// Function called when tool was released and set inactive.
    func deactivate() { /* Implementation in subclasses */ }

    /// Function called on plane update when the tool is active.
    func update() { /* Implementation in subclasses */ }

    /// Function called when tool operation was cancelled.
    func cancel() { /* Implementation in subclasses */ }

    // func getCursorType()
   
    func handleEvent(_ event: ToolEvent) -> EngagementResult {
        return .pass
    }
}

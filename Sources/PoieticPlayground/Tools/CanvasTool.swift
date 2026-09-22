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

@MainActor
struct ToolContext {
    private unowned let workspace: any WorkspaceServices
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
    unowned let document: Document

    /// Canvas the tool is bound to.
    ///
    /// Tool is bound to a canvas together with a document on activation.
    ///
    /// Functions typically used:
    ///
    /// - ``DiagramCanvas/screenToWorld(_:)->Vector2D``
    /// - ``DiagramCanvas/hitTarget(screenPosition:)``
    /// - ``DiagramCanvas/zoomLevel``
    ///
    unowned let canvas: DiagramCanvas
    
    public init(workspace: any WorkspaceServices, document: Document, canvas: DiagramCanvas) {
        self.workspace = workspace
        self.document = document
        self.canvas = canvas
    }
    
    func switchTool(_ tool: CanvasToolType) {
        workspace.switchTool(tool)
    }
    func openIssues(for object: ObjectID?) {
        workspace.openIssues(for: object)
    }
    func centerView(at position: Vector2D, zoom: Double? = nil) {
        workspace.centerView(at: position, zoom: zoom)
    }
}


/// Protocol for canvas tools.
///
/// Subclasses must implement ``makeInteraction(context:)`` and return a ``ToolInteraction``
/// object that will handle the events.
///
/// Optionally, if the tool uses an item from a palette, it should provide
/// a list of palette items through ``paletteItems(in:)``.
///
@MainActor
protocol CanvasTool: AnyObject {
    static var type: CanvasToolType { get }
    static var iconKey: IconKey { get }
    static var isRepeating: Bool { get }

    var isLocked: Bool { get set }
    var selectedPaletteItem: String? { get set }
    
    func paletteItems(in context: ToolContext) -> [PaletteItem]
    func makeInteraction(context: ToolContext) -> any ToolInteraction
}

extension CanvasTool {
    func paletteItems(in context: ToolContext) -> [PaletteItem] {
        return [] // Empty default
    }
}

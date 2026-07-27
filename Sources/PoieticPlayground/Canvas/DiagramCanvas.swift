//
//  DiagramCanvas.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 31/01/2026.
//

import CIimgui
import Diagramming
import PoieticCore

/// View that draws a diagram and handles events to be dispatched to canvas tools.
///
/// Responsibilities:
/// - Owns overlays and Cairo drawing contexts
/// - Performs diagram scene rendering
///
/// The canvas draws a scene rooted in ``/Diagramming/DiagramCanvas``.
///
class DiagramCanvas: View {
    static let DefaultHitRadius: Double = 5.0

    var debugRendering: Bool = false
    
    weak var document: Document?
    internal var world: World {
        guard let document else { fatalError("DiagramCanvas used before binding")}
        return document.world
    }
    /// Diagram presented in this canvas view.
    ///
    /// Owned and managed by the ``Document``.
    ///
    /// - SeeAlso: ``scene`` – renderable representation of the diagram.
    var diagram: RuntimeEntity?

    /// Root entity for diagram canvas scene hierarchy presented in this canvas.
    ///
    /// Owned and managed by this diagram canvas view.
    ///
    /// When there is no canvas scene, it is created on the next ``update(_:)`` from
    /// the ``diagram``.
    ///
    /// - SeeAlso: ``diagram`` – source for the scene.
    var scene: RuntimeEntity?

    var style: CanvasStyle

    // TODO: Not fully implemented, only one overlay at the moment
    var overlays: OverlayStack
    /// Overlay for the main content – diagram blocks, connectors, labels.
    var mainOverlay: Overlay
    /// Interactive preview of connection, placement or other operations.
    var previewOverlay: Overlay
    var indicatorOverlay: Overlay
    var highlightOverlay: Overlay

    var isMouseInViewport: Bool = false
    var inputState: InputState = InputState()
    
    var canvasPos = ImVec2(0.0, 0.0)          // Screen position of canvas
    var canvasSize = ImVec2(0.0, 0.0)         // Screen size of canvas

    /// Canvas view offset in world coordinates.
    ///
    /// - SeeAlso: ``setView(offset:zoom:)``, ``zoomLevel``
    private(set) var viewOffset: Vector2D = .zero

    /// Canvas view scale.
    ///
    /// - SeeAlso: ``setView(offset:zoom:)``, ``viewOffset``
    ///
    private(set) var zoomLevel: Double = 1.0
    
    // TODO: Replace the viewOffset and zoomLevel variables with viewportState
    var viewportState: ViewportState { ViewportState(offset: viewOffset, zoom: zoomLevel)}
    
    /// Transformation from world coordinates to the drawing context/surface coordinates.
    ///
    /// The transform is derived from canvas view offset and zoom level.
    ///
    /// - SeeAlso: ``setView(offset:zoom:)``
    private(set) var toOverlayTransform: AffineTransform = .identity
    
    /// Grid spacing in world coordinates.
    var gridSize: Double = 50.0
    var showGrid = true

    var editorManager: InlineEditorManager

    init(document: Document? = nil) {
        self.document = document
        self.style = CanvasStyle.Default

        self.overlays = OverlayStack()
        
        self.mainOverlay = Overlay(name: "main", type: .main)
        self.overlays.add(self.mainOverlay)
        self.previewOverlay = Overlay(name: "preview", type: .preview)
        self.overlays.add(self.previewOverlay)
        self.indicatorOverlay = Overlay(name: "indicator", type: .indicator)
        self.overlays.add(self.indicatorOverlay)
        self.highlightOverlay = Overlay(name: "highlight", type: .highlight)
        self.overlays.add(self.highlightOverlay)

        self.editorManager = InlineEditorManager()
        
        self.editorManager.register(name: "name", editor: NameInlineEditor())
        self.editorManager.register(name: "formula", editor: FormulaInlineEditor())
        self.editorManager.register(name: "delay",
                                    editor: NumericValueInlineEditor(attribute: "delay_duration", iconKey: .timeWindow))
        self.editorManager.register(name: "smooth",
                                    editor: NumericValueInlineEditor(attribute: "window_time", iconKey: .timeWindow))
    }
    
    func bind(_ document: Document) {
        self.document = document
        self.editorManager.bind(document: document, canvas: self)
    }
    
    /// Convert screen coordinates to world coordinates
    func screenToWorld(_ screenPos: ImVec2) -> ImVec2 {
        let worldPos = Vector2D(screenPos - canvasPos) / Double(zoomLevel) + viewOffset
        return ImVec2(worldPos)
    }
    func screenToWorld(_ screenPos: ImVec2) -> Vector2D {
        let worldPos = Vector2D(screenPos - canvasPos) / Double(zoomLevel) + viewOffset
        return worldPos
    }

    /// Convert world coordinates to ImGui screen coordinates.
    ///
    /// - Note: For drawing use the ``toOverlayTransform``.
    ///
    func worldToScreen(_ worldPos: Vector2D) -> ImVec2 {
        let screenPos = (worldPos - viewOffset) * Double(zoomLevel)
        return ImVec2(screenPos) + canvasPos
    }
   
    /// Convert world coordinates to scene coordinates.
    func worldToScene(_ worldPos: Vector2D) -> Vector2D {
        return toOverlayTransform.apply(to: worldPos)
    }
    func sceneToWorld(_ scenePos: Vector2D) -> Vector2D {
        let worldPos = scenePos / zoomLevel + viewOffset
        return worldPos
    }
    
    var visibleWorldRect: Rect2D {
        Rect2D(origin: viewOffset, size: (Vector2D(canvasSize) / zoomLevel))
    }
    
    // MARK: - Update and Events
    
    func update(_ timeDelta: Double) {
//        overlays.ensureSize(width: Int32(canvasSize.x),
//                            height: Int32(canvasSize.y))

        if scene == nil {
            print("DEBUG: Recreating scene, diagram=\(diagram != nil ? "yes" : "nil")")
            createScene()
        }
        
        if let scene {
            print("DEBUG: scene children count: \(scene.children.count)")
            for child in scene.children {
                let hasBlock = child.contains(BlockCanvasNode.self) ? "Block" : ""
                let hasConn = child.contains(ConnectorCanvasNode.self) ? "Conn" : ""
                let hasPict = child.target(DiagramSceneNode.Pictogram.self) != nil ? "+pictogram" : ""
                let posComp: PositionComponent? = child.component()
                let pos = posComp.map { String(describing: $0.position) } ?? "(no position)"
                print("  child: \(hasBlock)\(hasConn) \(hasPict) pos: \(pos)")
            }
            print("DEBUG: -- END OF SCENE --")
        }
    }

    func onSelectionChanged(_ document: Document) {
        // TODO: Make only selection overlay dirty (once we have selection overlays)
        overlays.setAllNeedsRender()
    }

    /// Update renderable scene and mark the whole canvas as needing to be rendered.
    ///
    func onDesignFrameChanged(_ document: Document) {
        self.diagram = document.mainDiagram
        
        // TODO: Recycle scene
        if let scene, world.contains(scene) {
            scene.despawn()
        }
        // Scene will be created in next update()
        scene = nil
    }
    
    private func createScene() {
        guard let diagram else {
            self.scene = nil
            return
        }
        let composer = DiagramSceneComposer(world: world)

        let scene = composer.createScene(diagram: diagram, viewport: viewportState)

        scene.setComponent(Diagram.DirtyContent.all)

        let provider = CairoLayoutProvider(context: mainOverlay.context!, style: style)
        scene.setComponent(SceneLayoutProvider(provider: provider))
        
        self.scene = scene
        overlays.setAllNeedsRender()
    }

    func onSimulationPlayerStep(_ document: Document) {
        indicatorOverlay.setNeedsRender()
    }


    // MARK: - Drawing
    
    func draw() {
        let viewport = ImGui.GetMainViewport()
        ImGui.SetNextWindowPos(viewport.pointee.WorkPos, ImGuiCond(ImGuiCond_Always.rawValue), ImVec2(0, 0))
        ImGui.SetNextWindowSize(viewport.pointee.WorkSize, ImGuiCond(ImGuiCond_Always.rawValue))

        ImGui.Begin("DiagramCanvas", nil,
            ImGuiWindowFlags_NoDecoration |
            ImGuiWindowFlags_NoMove |
            ImGuiWindowFlags_NoBringToFrontOnFocus |
            ImGuiWindowFlags_NoNavFocus)
        
        // Canvas color
        let color: Color
        if let canvasStyle = style.shapeStyle(class: .canvas) {
            color = canvasStyle.fill ?? CanvasStyle.DefaultCanvasColor
        }
        else {
            color = CanvasStyle.DefaultCanvasColor
        }
        
        // Disable padding
        ImGui.PushStyleVar(ImGuiStyleVar(ImGuiStyleVar_WindowPadding.rawValue), ImVec2(0, 0))
        ImGui.PushStyleColor(ImGuiCol(ImGuiCol_ChildBg.rawValue), color.imIntValue)
        ImGui.BeginChild("canvas",
                         ImVec2(0.0, 0.0),
                         ImGuiChildFlags_None | ImGuiChildFlags_Borders,
                         ImGuiWindowFlags_None | ImGuiWindowFlags_NoMove)
        ImGui.PopStyleColor()
        ImGui.PopStyleVar()

        // Note: We need to do it here for processUnhandledInput(...) to correctly capture
        // the mouse events for canvas. If there is a better solution, I am open.
        isMouseInViewport = ImGui.IsWindowHovered(
            ImGuiHoveredFlags_ChildWindows |
            ImGuiHoveredFlags_AllowWhenBlockedByPopup
        )

        canvasPos = ImGui.GetCursorScreenPos()
        canvasSize = ImGui.GetContentRegionAvail()
        overlays.ensureSize(width: Int32(canvasSize.x), height: Int32(canvasSize.y))

        drawOverlays()
        try! overlays.uploadIfNeeded()
        drawOverlayTextures()
       
        editorManager.draw()
        
        ImGui.EndChild()
        ImGui.End()
    }
    
    func drawOverlays() {
        guard let scene else { return }
        assert(scene.contains(DiagramScene.self))

        let renderer = CairoDiagramSceneRenderer(style: style, debug: debugRendering)
        
        // TODO: Handle exceptions
        if mainOverlay.needsRender {
            try! mainOverlay.render { context in
//                drawGrid(context)
                renderer.render(scene, context: context)
//                drawHandles(context)
            }
        }
        if previewOverlay.needsRender {
            try! previewOverlay.render { context in
                renderer.render(scene, context: context)
            }
        }
        if highlightOverlay.needsRender {
            try! highlightOverlay.render { context in
                renderer.render(scene, context: context)
            }
        }
        if indicatorOverlay.needsRender {
            try! indicatorOverlay.render { context in
                renderer.render(scene, context: context)
            }
        }
    }

    private func drawOverlayTextures() {
        guard let drawList = ImGui.GetWindowDrawList() else { return }
        guard !overlays.textures().isEmpty else {
            drawTextureError()
            return
        }
        let backend = GraphicsBackend.shared

        backend.withBlendMode(.premultiplied, drawList: drawList) {
            for texture in overlays.textures() {
                drawList.pointee.AddImage(
                    texture.imTextureRef,
                    canvasPos, canvasPos + canvasSize,
                    ImVec2(0, 0), ImVec2(1, 1), 0xFFFFFFFF
                )
            }
        }
    }
    
    private func drawTextureError() {
        let drawList = ImGui.GetWindowDrawList()
        let errorColor = Color.screenRed.withTransparency(0.3).imIntValue

        drawList?.pointee.AddRectFilled(canvasPos, canvasPos+canvasSize, errorColor)
        
        let errorText = "Texture Upload Failed"
        let textSize = ImGui.CalcTextSize(errorText)
        let textPos = ImVec2(
            canvasPos.x + (canvasSize.x - textSize.x) / 2,
            canvasPos.y + (canvasSize.y - textSize.y) / 2
        )
        drawList?.pointee.AddText(textPos, Color.white.imIntValue, errorText, nil)
    }

    // MARK: - Canvas Control Methods
    func resetView() {
        self.setView(offset: .zero, zoom: 1.0)
    }
    
    func setView(offset: Vector2D, zoom: Double) {
        viewOffset = offset
        zoomLevel = max(0.01, min(100.0, zoom))
        toOverlayTransform = AffineTransform(translation: -viewOffset)
                                .scaled(Vector2D(zoomLevel, zoomLevel))

        // Viewport Changed
        if let scene {
            scene.setComponent(self.viewportState)
            scene.setComponent(Diagram.DirtyContent.geometry)
        }
        overlays.setAllNeedsRender()
    }
    
    func centerView(at worldPoint: Vector2D, zoom: Double? = nil) {
        let useZoom = zoom ?? self.zoomLevel
        let canvasCenter = Vector2D(canvasSize) / 2.0
        let offset = worldPoint - (canvasCenter / useZoom)
        setView(offset: offset, zoom: useZoom)
    }
    func hitTarget(screenPosition: ImVec2) -> CanvasHitTarget? {
        guard let scene
        else { return nil }

        let scenePosition = worldToScene(screenToWorld(screenPosition))
        let radius = DiagramCanvas.DefaultHitRadius / zoomLevel
        guard let entity = hitTest(node: scene, scenePosition: scenePosition, radius: radius),
              let parent: RuntimeEntity = entity.target(ChildOf.self)
        else { return nil }

        // Determine hit target type
        //
        if entity.contains(CanvasHandle.self) {
            return CanvasHitTarget.handle(entity.runtimeID)
        } else if parent.relates(DiagramSceneNode.PrimaryLabel.self, to: entity) {
            return CanvasHitTarget.object(entity.runtimeID, .primaryLabel)
        } else if parent.relates(DiagramSceneNode.SecondaryLabel.self, to: entity) {
            return CanvasHitTarget.object(entity.runtimeID, .secondaryLabel)
        } else if entity.contains(IssueIndicatorCanvasNode.self) {
            return CanvasHitTarget.object(entity.runtimeID, .issueIndicator)
        } else if entity.contains(BlockCanvasNode.self) || entity.contains(ConnectorCanvasNode.self) {
            return CanvasHitTarget.object(entity.runtimeID, .body)
        }
        else {
            return nil
        }
    }
    func hitTest(node: RuntimeEntity, scenePosition: Vector2D, radius: Double) -> RuntimeEntity? {
        for child in node.children {
            guard let region: TouchRegion = child.component()
            else { continue }
            if region.isHit(at: scenePosition, radius: radius) {
                return child
            }
        }
        return nil
    }
    
    // MARK: - Inline Editors
    func openInlineEditorForSelection(_ editorName: String) {
        guard let document,
              let objectID = document.selection.selectionOfOne(),
              let entity = document.world.entity(objectID)
        else { return }
        
        self.editorManager.openEditor(editorName, for: entity)
    }

    func openSecondaryInlineEditorForSelection() {
        guard let document,
              let objectID = document.selection.selectionOfOne(),
              let entity = document.world.entity(objectID),
              let object = entity.designObject
        else { return }
       
        if object.type.hasTrait(.Formula) {
            self.editorManager.openEditor("formula", for: entity)
        }
        else if object.type.hasTrait(.Delay) {
            self.editorManager.openEditor("delay", for: entity)
        }
        else if object.type.hasTrait(.Smooth) {
            self.editorManager.openEditor("smooth", for: entity)
        }
        else if object.type.hasTrait(.GraphicalFunction) {
            // TODO: Implement graphical function editor
            self.editorManager.openEditor("graphical_function", for: entity)
        }
    }
}

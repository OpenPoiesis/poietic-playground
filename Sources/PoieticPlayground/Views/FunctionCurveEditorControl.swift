//
//  FunctionCurveEditorView.swift
//  PoieticPlayground
//
//  Stub for the curve editor widget. Reusable by both the panel and the inline editor.
//

// Translated from early Poietic-Playground Godot prototype

import CIimgui
import PoieticCore
import Diagramming // for Vector2D
import PoieticFlows

/// Interactive 2D curve editor for graphical function points.
///
/// Displays a grid-based graph with editable control points. Handles point creation,
/// dragging, deletion, and selection. Used as a subview by `GraphicalFunctionPanel`
/// and `GraphicalFunctionInlineEditor`.
///
/// Corresponds to `FunctionCurveEditor` in the Godot prototype.
@MainActor
class FunctionCurveEditorControl {

    // MARK: - Data

    /// Unsorted control points in value space.
    var points: [Vector2D] = []

    /// Interpolation method for the displayed curve.
    var interpolation: GraphicalFunction.InterpolationMethod = .linear

    // MARK: - Visual range

    var minX: Double = 0.0
    var maxX: Double = 100.0
    var minY: Double = 0.0
    var maxY: Double = 100.0

    // MARK: - Visual settings

    var gridSegmentsX: Int = 10
    var gridSegmentsY: Int = 10
    var pointRadius: Float = 6.0

    // MARK: - Colors
    // TODO: resolved colors from style
    var backgroundColor: UInt32 = 0xFF282828
    var gridColor: UInt32 = 0xFF505050
    var axisColor: UInt32 = 0xFF808080
    var curveColor: UInt32 = 0xFF66B2FF
    var pointNormalColor: UInt32 = 0xFFCCCCCC
    var pointSelectedColor: UInt32 = 0xFFFFDD44
    var pointDraggingColor: UInt32 = 0xFFFF8855

    // MARK: - Interaction state

    private(set) var selectedPointIndex: Int? = nil
    private var draggingPointIndex: Int? = nil
    private var draggingPointValue: Vector2D = .zero

    // MARK: - Callbacks

    var onPointsChanged: (() -> Void)?
    var onPointSelected: ((Int) -> Void)?

    // MARK: - Drawing

    /// Draw the curve editor within the current ImGui window / child region.
    /// - Parameter size: The drawable area size.
    func draw(size: ImVec2) {
        let drawList = ImGui.GetWindowDrawList()
        let origin = ImGui.GetCursorScreenPos()

        // Background
        drawList?.pointee.AddRectFilled(origin, origin + size, backgroundColor)

        // Grid
        drawGrid(drawList: drawList, origin: origin, size: size)

        // Axes
        drawAxes(drawList: drawList, origin: origin, size: size)

        // Curve
        drawCurve(drawList: drawList, origin: origin, size: size)

        // Points
        drawPoints(drawList: drawList, origin: origin, size: size)

        // Invisible interaction area
        let cursor = ImGui.GetCursorPos()
        ImGui.InvisibleButton("##curve_area", size, ImGuiButtonFlags(ImGuiButtonFlags_None.rawValue))
        let isActive = ImGui.IsItemActive()
        let isHovered = ImGui.IsItemHovered()
        let mousePos = ImGui.GetMousePos()
//        let localPos = ImVec2(mousePos.x - origin.x, size.y - (mousePos.y - origin.y)) // flip Y

        if isHovered {
            if ImGui.IsMouseClicked(ImGuiMouseButton(ImGuiMouseButton_Left.rawValue), false) {
                handleMouseDown(screenPos: mousePos, origin: origin, size: size)
            }
            if ImGui.IsMouseReleased(ImGuiMouseButton(ImGuiMouseButton_Left.rawValue)) {
                handleMouseUp()
            }
            if isActive {
                handleMouseDrag(screenPos: mousePos, origin: origin, size: size)
            }
        }
        ImGui.SetCursorPos(cursor)
    }

    // MARK: - Coordinate transforms

    func valueToScreen(_ value: Vector2D, origin: ImVec2, size: ImVec2) -> ImVec2 {
        let x = Float((value.x - minX) / (maxX - minX)) * size.x + origin.x
        let y = origin.y + size.y - Float((value.y - minY) / (maxY - minY)) * size.y
        return ImVec2(x, y)
    }

    func screenToValue(_ screen: ImVec2, origin: ImVec2, size: ImVec2) -> Vector2D {
        let x = Double((screen.x - origin.x) / size.x) * (maxX - minX) + minX
        let y = Double((origin.y + size.y - screen.y) / size.y) * (maxY - minY) + minY
        return Vector2D(x: x, y: y)
    }

    // MARK: - Grid & axes drawing (stubs)

    private func drawGrid(drawList: UnsafeMutablePointer<ImDrawList>?, origin: ImVec2, size: ImVec2) {
        // TODO: Draw vertical and horizontal grid lines
    }

    private func drawAxes(drawList: UnsafeMutablePointer<ImDrawList>?, origin: ImVec2, size: ImVec2) {
        // TODO: Draw X and Y axes
    }

    // MARK: - Curve drawing (stub — delegates to GraphicalFunction math)

    private func drawCurve(drawList: UnsafeMutablePointer<ImDrawList>?, origin: ImVec2, size: ImVec2) {
        guard points.count >= 2 else { return }
        let sorted = sortedPoints()
        // TODO: Sample the curve using GraphicalFunction.apply(x:) at regular intervals,
        //       convert to screen space, and draw as a polyline.
    }

    private func drawPoints(drawList: UnsafeMutablePointer<ImDrawList>?, origin: ImVec2, size: ImVec2) {
        for (i, pt) in points.enumerated() {
            let sp = valueToScreen(pt, origin: origin, size: size)
            let color: UInt32
            if i == draggingPointIndex { color = pointDraggingColor }
            else if i == selectedPointIndex { color = pointSelectedColor }
            else { color = pointNormalColor }
            drawList?.pointee.AddCircleFilled(sp, pointRadius, color)
            drawList?.pointee.AddCircle(sp, pointRadius, 0xFF000000, 0, 2.0)
        }
    }

    // MARK: - Mouse handling

    private func handleMouseDown(screenPos: ImVec2, origin: ImVec2, size: ImVec2) {
        for (i, pt) in points.enumerated() {
            let sp = valueToScreen(pt, origin: origin, size: size)
            let dx = screenPos.x - sp.x
            let dy = screenPos.y - sp.y
            if Float(dx*dx + dy*dy) <= pointRadius + 2 {
                draggingPointIndex = i
                draggingPointValue = pt
                selectedPointIndex = i
                onPointSelected?(i)
                return
            }
        }
        // No hit — create new point
        let value = screenToValue(screenPos, origin: origin, size: size)
        let clamped = Vector2D(
            x: max(minX, min(maxX, value.x)),
            y: max(minY, min(maxY, value.y))
        )
        points.append(clamped)
        sortPoints()
        draggingPointIndex = points.firstIndex(where: { $0.x == clamped.x && $0.y == clamped.y })
        draggingPointValue = clamped
        selectedPointIndex = draggingPointIndex
        onPointsChanged?()
    }

    private func handleMouseUp() {
        draggingPointIndex = -1
    }

    private func handleMouseDrag(screenPos: ImVec2, origin: ImVec2, size: ImVec2) {
        guard draggingPointIndex != nil else { return }
        let newValue = screenToValue(screenPos, origin: origin, size: size)
        for i in 0..<points.count where points[i] == draggingPointValue {
            points[i] = newValue
            draggingPointValue = newValue
            sortPoints()
            self.draggingPointIndex = points.firstIndex(where: { $0 == newValue })
            break
        }
        onPointsChanged?()
    }

    // MARK: - Point operations

    func sortPoints() {
        points.sort { $0.x < $1.x }
    }

    func sortedPoints() -> [Vector2D] {
        points.sorted { $0.x < $1.x }
    }

    func addPoint(_ point: Vector2D) {
        points.append(point)
        sortPoints()
        onPointsChanged?()
    }

    func removePoint(at index: Int) {
        guard index >= 0, index < points.count else { return }
        let sorted = sortedPoints()
        guard index < sorted.count else { return }
        let target = sorted[index]
        points.removeAll { $0 == target }
        if selectedPointIndex == index { selectedPointIndex = -1 }
        onPointsChanged?()
    }

    func clearSelection() {
        selectedPointIndex = -1
    }

    /// Fit the visible range to contain all points.
    func fitRange(minSize: Vector2D = Vector2D(1, 1)) {
        guard !points.isEmpty else { return }
        minX = points.map(\.x).min()!
        maxX = points.map(\.x).max()!
        minY = points.map(\.y).min()!
        maxY = points.map(\.y).max()!
        if abs(maxX - minX) < 1e-6 { maxX = minX + minSize.x }
        if abs(maxY - minY) < 1e-6 { maxY = minY + minSize.y }
    }
}

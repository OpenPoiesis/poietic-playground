//
//  FunctionCurveEditorView.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 08/08/2026.

//  Curve editor widget. Reusable by both the panel and the inline editor.
//
// Ported with help of an agent from Playground prototype written in Godot.

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
class CurveEditorControl {

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
    var backgroundColor: UInt32   = 0xFFFFFFFF   // crisp white
    var gridColor: UInt32         = 0xFFE0E0E8   // cool light gray
    var axisColor: UInt32         = 0xFFB0B0B8   // mid gray
    var curveColor: UInt32        = 0xFF3B82D0   // medium blue, visible on white
    var pointNormalColor: UInt32  = 0xFF585860   // dark slate
    var pointSelectedColor: UInt32 = 0xFFD4980A   // amber gold
    var pointDraggingColor: UInt32 = 0xFFE04830   // warm red
    // Dark - for future theming
    //    var backgroundColor: UInt32   = 0xFF1E1E28   // charcoal, near-black with blue undertone
    //    var gridColor: UInt32         = 0xFF3A3A48   // muted slate
    //    var axisColor: UInt32         = 0xFF686878   // mid gray
    //    var curveColor: UInt32        = 0xFF5E9CF4   // soft blue
    //    var pointNormalColor: UInt32  = 0xFFC8C8D0   // light silver
    //    var pointSelectedColor: UInt32 = 0xFFF0C944   // warm gold
    //    var pointDraggingColor: UInt32 = 0xFFFF7744   // vivid orange

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

        drawGrid(drawList: drawList, origin: origin, size: size)
        drawAxes(drawList: drawList, origin: origin, size: size)
        drawCurve(drawList: drawList, origin: origin, size: size)
        drawPoints(drawList: drawList, origin: origin, size: size)

        // Invisible interaction area
        let cursor = ImGui.GetCursorPos()
        ImGui.InvisibleButton("##curve_area", size, ImGuiButtonFlags(ImGuiButtonFlags_None.rawValue))
        let isActive = ImGui.IsItemActive()
        let isHovered = ImGui.IsItemHovered()
        let mousePos = ImGui.GetMousePos()

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
        ImGui.SetCursorPos(ImVec2(cursor.x, cursor.y + size.y))
    }

    // MARK: - Coordinate transforms

    func valueToScreen(_ value: Vector2D, origin: ImVec2, size: ImVec2) -> ImVec2 {
        let x = origin.x +          Float((value.x - minX) / (maxX - minX)) * size.x
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
        for i in 1..<gridSegmentsX {
            let x = origin.x + (size.x / Float(gridSegmentsX)) * Float(i)
            drawList?.pointee.AddLine(
                ImVec2(x, origin.y),
                ImVec2(x, origin.y + size.y),
                gridColor, 1.0)
        }
        for i in 1..<gridSegmentsY {
            let y = origin.y + (size.y / Float(gridSegmentsY)) * Float(i)
            drawList?.pointee.AddLine(
                ImVec2(origin.x, y),
                ImVec2(origin.x + size.x, y),
                gridColor, 1.0)
        }
    }

    private func drawAxes(drawList: UnsafeMutablePointer<ImDrawList>?, origin: ImVec2, size: ImVec2) {
        // X-axis at the bottom
        drawList?.pointee.AddLine(
            ImVec2(origin.x, origin.y + size.y),
            ImVec2(origin.x + size.x, origin.y + size.y),
            axisColor, 2.0)
        // Y-axis at the left
        drawList?.pointee.AddLine(
            ImVec2(origin.x, origin.y),
            ImVec2(origin.x, origin.y + size.y),
            axisColor, 2.0)
    }

    // MARK: - Curve drawing (stub — delegates to GraphicalFunction math)

    private func drawCurve(drawList: UnsafeMutablePointer<ImDrawList>?, origin: ImVec2, size: ImVec2) {
        guard points.count >= 2 else { return }
        let sorted = sortedPoints()
        let path = GraphicalFunction.bezierPath(sortedPoints: sorted, method: interpolation)
        let screenPath = path.transform(valueToScreenTransform(origin: origin, size: size))
        drawList?.pointee.StrokePath(screenPath, color: Color(curveColor), lineWidth: 2.0)
    }

    /// Returns an AffineTransform that maps value-space to screen-space.
    private func valueToScreenTransform(origin: ImVec2, size: ImVec2) -> AffineTransform {
        let sx = Double(size.x) / (maxX - minX)
        let sy = -Double(size.y) / (maxY - minY)
        let tx = Double(origin.x) - minX * sx
        let ty = Double(origin.y + size.y) + minY * (-sy)
        return AffineTransform(a: sx, b: 0, c: 0, d: sy, tx: tx, ty: ty)
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

    /// Replace a point by its current value. Finds the point in the unsorted array
    /// by value, replaces it, re-sorts, and fires `onPointsChanged`.
    func replacePoint(oldValue: Vector2D, newValue: Vector2D) {
        guard let index = points.firstIndex(where: { $0 == oldValue }) else { return }
        points[index] = newValue
        sortPoints()
        onPointsChanged?()
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

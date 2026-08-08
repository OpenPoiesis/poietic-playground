//
//  GraphicalFunctionInlineEditor.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 08/08/2026.
//
//  Inline graphical function editor — a compact overlay that
//  appears near the selected object on the canvas.
//
//  Ported with help of an agent from Playground prototype written in Godot.

import CIimgui
import PoieticCore
import PoieticFlows
import Diagramming

/// Inline editor for graphical function control points.
///
/// Displays a mini curve editor with Accept / Cancel buttons overlaid on the
/// canvas near the selected object. Has an optional "Open Full Panel" button
/// that opens the stand-alone `GraphicalFunctionPanel`.
///
/// Corresponds to `GraphCurvesInlineEditor` in the Godot prototype.
@MainActor
class GraphicalFunctionInlineEditor: InlineEditor {

    static let PopupID = "##graphical_function_inline_editor"
    var worldPosition: Vector2D = .zero

    /// The curve editor subview.
    private let curveView = FunctionCurveEditorControl()

    /// Object being edited.
    private var editingObjectID: ObjectID?
    private var grabFocus: Bool = false

    // MARK: - InlineEditor overrides

    override func open(for entity: RuntimeEntity) -> Bool {
        guard let object = entity.designObject,
              object.type.hasTrait(.GraphicalFunction),
              let block: DiagramBlock = entity.component()
        else { return false }

        editingObjectID = object.objectID
        grabFocus = true
        worldPosition = block.labelAnchorPosition

        let rawPoints: [Vector2D] = object["graphical_function_points"] ?? []
        curveView.points = rawPoints

        let methodName: String = object["interpolation_method"] ?? "linear"
        curveView.interpolation = parseInterpolation(methodName)
        curveView.fitRange()

        return true
    }

    override func draw() -> Bool {
        guard let editingObjectID,
              let canvas
        else { return true }

        let screenPos = canvas.worldToScreen(worldPosition)
        ImGui.SetNextWindowPos(screenPos, 0, ImVec2(0.5, 0))

        let flags: ImGuiWindowFlags =
                        ImGuiWindowFlags_NoTitleBar
                        | ImGuiWindowFlags_NoResize
                        | ImGuiWindowFlags_NoMove
                        | ImGuiWindowFlags_AlwaysAutoResize

        if !ImGui.IsPopupOpen(Self.PopupID) {
            ImGui.OpenPopup(Self.PopupID)
        }

        if ImGui.BeginPopup(Self.PopupID, flags) {
            defer {
                ImGui.EndPopup()
                grabFocus = false
            }

            let curveSize = ImVec2(220, 180)
            if grabFocus { ImGui.SetKeyboardFocusHere() }
            ImGui.BeginChild("##curve_scroll", curveSize, ImGuiChildFlags(ImGuiChildFlags_Borders.rawValue))
            curveView.draw(size: curveSize)
            ImGui.SetCursorPosY(ImGui.GetCursorPosY() + curveSize.y)
            ImGui.Dummy(ImVec2())
            ImGui.EndChild()

            let escapePressed = ImGui.IsKeyPressed(ImGuiKey(ImGuiKey_Escape.rawValue), false)

            if escapePressed {
                ImGui.CloseCurrentPopup()
                return true
            }

            ImGui.Separator()

            if ImGui.Button("Open Editor", ImVec2(100, 0)) {
                // How to reference a panel in the Application?
                return true
            }

            if ImGui.Button("Accept", ImVec2(100, 0)) {
                commitChanges()
                ImGui.CloseCurrentPopup()
                return true
            }
            ImGui.SameLine()
            if ImGui.Button("Cancel", ImVec2(100, 0)) {
                ImGui.CloseCurrentPopup()
                return true
            }
        }

        return false
    }

    override func close() {
        editingObjectID = nil
        curveView.points = []
    }

    // MARK: - Actions

    private func commitChanges() {
        guard let document, let editingObjectID else { return }
        let trans = document.createOrReuseTransaction()
        let mutable = trans.mutate(editingObjectID)

        let sorted = curveView.sortedPoints()
        mutable["graphical_function_points"] = Variant(sorted)
        mutable["interpolation_method"] = Variant(interpolationMethodName(curveView.interpolation))
    }

    // MARK: - Helpers

    // TODO: Remove this. Use InterpolationMethod directly
    private func parseInterpolation(_ name: String) -> GraphicalFunction.InterpolationMethod {
        switch name.lowercased() {
        case "step": return .step
        case "cubic": return .cubic
        default: return .linear
        }
    }

    // TODO: Remove this. Use InterpolationMethod directly
    private func interpolationMethodName(_ method: GraphicalFunction.InterpolationMethod) -> String {
        switch method {
        case .step: return "step"
        case .cubic: return "cubic"
        case .linear: return "linear"
        default: return "linear"
        }
    }
}

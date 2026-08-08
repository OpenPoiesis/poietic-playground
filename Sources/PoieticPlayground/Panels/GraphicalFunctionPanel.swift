//
//  GraphicalFunctionPanel.swift
//  PoieticPlayground
//
//  Stub for the stand-alone graphical function editor panel.
//

import CIimgui
import PoieticCore
import PoieticFlows
import Diagramming

/// Full-featured panel for editing a graphical function's control points and
/// interpolation method. Contains a curve view, an editable points table, range
/// controls, and Set / Reset action buttons.
///
/// Like the inspector, it reacts to selection changes: when exactly one
/// GraphicalFunction object is selected, the editor is populated; otherwise
/// the UI is disabled and shows only an empty grid.
///
/// Corresponds to `GraphicalCurvesEditorWindow` in the Godot prototype.
@MainActor
class GraphicalFunctionPanel {

    // MARK: - State

    weak var document: Document?

    /// ObjectID currently being edited, if any.
    private var editingObjectID: ObjectID?

    /// The curve editor subview.
    private let curveView = FunctionCurveEditorControl()

    /// Points being edited — a working copy of the design object's data.
    private var workingPoints: [Vector2D] = []
    private var workingInterpolation: GraphicalFunction.InterpolationMethod = .linear

    /// Originals from the design object, for Reset.
    private var originalPoints: [Vector2D] = []
    private var originalInterpolation: GraphicalFunction.InterpolationMethod = .linear

    /// Whether the panel is active (exactly one GraphicalFunction selected).
    private var isActive: Bool = false

    // MARK: - Range fields (string buffers for ImGui input)

    private var minXStr: String = "0.0"
    private var maxXStr: String = "100.0"
    private var minYStr: String = "0.0"
    private var maxYStr: String = "100.0"

    // MARK: - Interpolation radio state

    private var interpolationLinear: Bool = true
    private var interpolationStep: Bool = false
    private var interpolationCubic: Bool = false

    // MARK: - Lifecycle

    func bind(_ document: Document) {
        self.document = document
    }
    
    func update(_ timeDelta: Double) {
        // Nothing yet
    }
    
    /// Called when the document selection changes.
    func onSelectionChanged(_ document: Document) {
        let selection = document.selection
        guard selection.ids.count == 1,
              let objectID = selection.ids.first,
              let frame = document.world.frame,
              let object = frame[objectID],
              object.type.hasTrait(.GraphicalFunction)
        else {
            isActive = false
            editingObjectID = nil
            curveView.points = []
            return
        }

        isActive = true
        editingObjectID = objectID

        // Read points from design object
        let rawPoints: [Vector2D] = object["graphical_function_points"] ?? []
        workingPoints = rawPoints
        originalPoints = rawPoints

        // Read interpolation method
        let methodName: String = object["interpolation_method"] ?? "linear"
        workingInterpolation = parseInterpolation(methodName)
        originalInterpolation = workingInterpolation

        // Push to curve view
        curveView.points = workingPoints
        curveView.interpolation = workingInterpolation
        curveView.fitRange()

        // Sync range fields
        syncRangeFieldsFromCurve()
        syncInterpolationRadio()
    }

    // MARK: - Drawing

    func draw() {
        guard let document else { return }

        ImGui.Begin("Graphical Function Editor")

        if !isActive {
            ImGui.TextUnformatted("Select a single Graphical Function object to edit.")
            ImGui.End()
            return
        }

        // -- Curve editor --
        let curveSize = ImVec2(Float(ImGui.GetContentRegionAvail().x), 350)
        ImGui.BeginChild("##curve_area", curveSize, ImGuiChildFlags(ImGuiChildFlags_Borders.rawValue))
        
        curveView.draw(size: curveSize)
        ImGui.EndChild()

        // -- Points table --
        drawPointsTable()

        // -- Range controls --
        drawRangeControls()

        // -- Interpolation --
        drawInterpolationControls()

        // -- Action buttons --
        drawActionButtons()

        ImGui.End()
    }

    // MARK: - Points table

    private func drawPointsTable() {
        guard ImGui.BeginTable("##points_table", 2,
            ImGuiTableFlags(ImGuiTableFlags_Borders |
                            ImGuiTableFlags_RowBg), ImVec2())
        else { return }

        ImGui.TableSetupColumn("X", ImGuiTableColumnFlags(ImGuiTableColumnFlags_None.rawValue), 0, 0)
        ImGui.TableSetupColumn("Y", ImGuiTableColumnFlags(ImGuiTableColumnFlags_None.rawValue), 0, 0)
        ImGui.TableHeadersRow()

        let sorted = curveView.sortedPoints()
        for point in sorted {
            ImGui.TableNextRow(ImGuiTableRowFlags(ImGuiTableRowFlags_None.rawValue), 0)
            // TODO: Editable cells — need per-cell buffer management
            //       and callbacks to update workingPoints ↔ curveView.points
            ImGui.TableNextColumn()
            ImGui.TextUnformatted(String(format: "%.2f", point.x))
            ImGui.TableNextColumn()
            ImGui.TextUnformatted(String(format: "%.2f", point.y))
        }
        ImGui.EndTable()

        // Add / Remove buttons
        if ImGui.Button("Add Point", ImVec2(120, 0)) {
            let midX = (curveView.minX + curveView.maxX) / 2
            let midY = (curveView.minY + curveView.maxY) / 2
            curveView.addPoint(Vector2D(x: midX, y: midY))
        }
        ImGui.SameLine()
        if ImGui.Button("Remove", ImVec2(120, 0)) {
            if let pointIndex = curveView.selectedPointIndex {
                curveView.removePoint(at: pointIndex)
            }
        }
    }

    // MARK: - Range controls

    private func drawRangeControls() {
        ImGui.TextUnformatted("View Range")
        let fieldWidth: Float = 80

        ImGui.PushItemWidth(fieldWidth)
        // TODO: Use InputText or InputDouble with proper buffer management
        if ImGui.InputText("Min X", &minXStr, 0, 0) { /* range changed */ }
        ImGui.SameLine()
        if ImGui.InputText("Max X", &maxXStr, 0, 0) { /* range changed */ }
        ImGui.SameLine()
        if ImGui.InputText("Min Y", &minYStr, 0, 0) { /* range changed */ }
        ImGui.SameLine()
        if ImGui.InputText("Max Y", &maxYStr, 0, 0) { /* range changed */ }
        ImGui.PopItemWidth()
    }

    // MARK: - Interpolation controls

    private func drawInterpolationControls() {
        ImGui.TextUnformatted("Interpolation")
        if ImGui.RadioButton("Linear", workingInterpolation == .linear) {
            setInterpolation(.linear)
        }
        ImGui.SameLine()
        if ImGui.RadioButton("Step", workingInterpolation == .step) {
            setInterpolation(.step)
        }
        ImGui.SameLine()
        if ImGui.RadioButton("Cubic", workingInterpolation == .cubic) {
            setInterpolation(.cubic)
        }
    }

    // MARK: - Action buttons

    private func drawActionButtons() {
        ImGui.Spacing()
        if ImGui.Button("Set", ImVec2(120, 0)) {
            commitChanges()
        }
        ImGui.SameLine()
        if ImGui.Button("Reset", ImVec2(120, 0)) {
            resetToOriginals()
        }
    }

    // MARK: - Actions

    private func commitChanges() {
        guard let document,
              let editingObjectID
        else { return }
        
        let trans = document.createOrReuseTransaction()
        let mutable = trans.mutate(editingObjectID)

        let sorted = curveView.sortedPoints()
        mutable["graphical_function_points"] = Variant(sorted)
        mutable["interpolation_method"] = Variant(interpolationMethodName(curveView.interpolation))
    }

    private func resetToOriginals() {
        workingPoints = originalPoints
        workingInterpolation = originalInterpolation
        curveView.points = originalPoints
        curveView.interpolation = originalInterpolation
        curveView.fitRange()
        syncRangeFieldsFromCurve()
        syncInterpolationRadio()
    }

    // MARK: - Helpers

    private func parseInterpolation(_ name: String) -> GraphicalFunction.InterpolationMethod {
        switch name.lowercased() {
        case "step": return .step
        case "cubic": return .cubic
        default: return .linear
        }
    }

    private func interpolationMethodName(_ method: GraphicalFunction.InterpolationMethod) -> String {
        switch method {
        case .step: return "step"
        case .cubic: return "cubic"
        case .linear: return "linear"
        default: return "linear"
        }
    }

    private func syncRangeFieldsFromCurve() {
        minXStr = String(format: "%.2f", curveView.minX)
        maxXStr = String(format: "%.2f", curveView.maxX)
        minYStr = String(format: "%.2f", curveView.minY)
        maxYStr = String(format: "%.2f", curveView.maxY)
    }

    private func syncInterpolationRadio() {
        interpolationLinear = (curveView.interpolation == .linear)
        interpolationStep = (curveView.interpolation == .step)
        interpolationCubic = (curveView.interpolation == .cubic)
    }

    private func setInterpolation(_ method: GraphicalFunction.InterpolationMethod) {
        workingInterpolation = method
        curveView.interpolation = method
        syncInterpolationRadio()
    }
}

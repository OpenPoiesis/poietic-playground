//
//  DebugDesignPanel.swift
//  PoieticPlayground
//
//  Debug panel for inspecting design objects and their raw data.
//
//  Created with help of an agent. Ported from original Godot prototype.

import CIimgui
import PoieticCore
import Diagramming

/// Panel that displays raw design object data for debugging purposes.
///
/// Left: list of currently selected objects (from document selection).
/// Right: detail view with object ID, snapshot ID, type, and attributes table.
///
/// Reflects selection changes live. No editing capability (yet).
///
/// Corresponds to `DevelopmentDebuggingWindow` in the Godot prototype.
@MainActor
class DebugDesignPanel: Panel {

    var isVisible: Bool = false

    weak var document: Document?

    // Selection tracking
    private var objectIDs: [ObjectID] = []
    private var selectedIndex: Int? = nil

    // MARK: - Panel

    func bind(_ document: Document) {
        self.document = document
        refreshFromSelection()
    }

    func update(_ timeDelta: Double) {}

    func onSelectionChanged(_ document: Document) {
        refreshFromSelection()
    }

    func draw() {
        guard let document, let plane = document.world.plane else {
            ImGui.Begin("Design Debug")
            ImGui.TextUnformatted("No design loaded.")
            ImGui.End()
            return
        }

        ImGui.Begin("Design Debug")

        // -- Left: object list --
        ImGui.BeginChild("##object_list", ImVec2(220, 0),
            ImGuiChildFlags(ImGuiChildFlags_ResizeX.rawValue))

        ImGui.TextUnformatted("Objects")
        ImGui.Separator()

        if objectIDs.isEmpty {
            ImGui.TextDisabledUnformatted("No objects selected.")
        } else {
            if ImGui.BeginListBox("##lb", ImVec2(-1, -1)) {
                for (index, objectID) in objectIDs.enumerated() {
                    let label = makeLabel(for: objectID, in: plane)
                    let isSelected = (index == selectedIndex)
                    if ImGui.Selectable(label, isSelected, 0, ImVec2()) {
                        selectedIndex = index
                    }
                }
                ImGui.EndListBox()
            }
        }

        ImGui.EndChild()
        ImGui.SameLine()

        // -- Right: detail --
        ImGui.BeginChild("##detail", ImVec2(0, 0),
            ImGuiChildFlags(ImGuiChildFlags_Borders.rawValue))

        if let selectedIndex, selectedIndex < objectIDs.count {
            let objectID = objectIDs[selectedIndex]
            if let object = plane[objectID] {
                drawObjectDetail(object)
            } else {
                ImGui.TextUnformatted("Object \(objectID) not found in current plane.")
            }
        } else {
            ImGui.TextUnformatted("Select an object for details.")
        }

        ImGui.EndChild()
        ImGui.End()
    }

    // MARK: - Detail

    private func drawObjectDetail(_ object: ObjectSnapshot) {
        ImGui.TextUnformatted("Object ID:")
        ImGui.SameLine()
        ImGui.TextUnformatted(object.objectID.stringValue)

        ImGui.TextUnformatted("Snapshot ID:")
        ImGui.SameLine()
        ImGui.TextUnformatted(object.snapshotID.stringValue)

        ImGui.TextUnformatted("Type:")
        ImGui.SameLine()
        ImGui.TextUnformatted(object.type.label)
        ImGui.SameLine()
        ImGui.TextDisabledUnformatted("(\(object.type.name))")

        // Topology
        ImGui.TextUnformatted("Topology:")
        ImGui.SameLine()
        switch object.topology {
        case .node:
            ImGui.TextUnformatted("node")
        case .edge(let origin, let target):
            ImGui.TextUnformatted("edge: \(origin) → \(target)")
        case .unstructured:
            ImGui.TextUnformatted("unstructured")
        default: break
        }

        ImGui.Separator()

        // Attributes table
        ImGui.TextUnformatted("Attributes:")
        drawAttributesTable(object)
    }

    // MARK: - Attributes table

    private func drawAttributesTable(_ object: ObjectSnapshot) {
        let attrs = object.type.attributes
        guard ImGui.BeginTable("##attrs", 2,
            ImGuiTableFlags(ImGuiTableFlags_Borders.rawValue |
                            ImGuiTableFlags_RowBg.rawValue |
                            ImGuiTableFlags_Resizable.rawValue |
                            ImGuiTableFlags_ScrollY.rawValue),
            ImVec2(0, -1))
        else { return }

        ImGui.TableSetupColumn("Attribute", 0, 0, 0)
        ImGui.TableSetupColumn("Value", 0, 0, 0)
        ImGui.TableHeadersRow()

        for attr in attrs {
            ImGui.TableNextRow(ImGuiTableRowFlags(ImGuiTableRowFlags_None.rawValue), 0)

            ImGui.TableNextColumn()
            ImGui.TextUnformatted(attr.name)

            ImGui.TableNextColumn()
            if let value: Variant = object[attr.name] {
                ImGui.TextUnformatted(truncatedValue(value))
            } else {
                ImGui.TextDisabledUnformatted("(nil)")
            }
        }

        ImGui.EndTable()
    }

    // MARK: - Helpers

    private func refreshFromSelection() {
        guard let document else {
            objectIDs = []
            selectedIndex = nil
            return
        }
        let idNumbers = document.selection.ids.map { $0.rawValue }
        objectIDs = idNumbers.sorted().map { ObjectID(intValue: $0) }

        if let selectedIndex {
            if selectedIndex >= objectIDs.count {
                self.selectedIndex = max(0, objectIDs.count - 1)
            }
        }
        else if !objectIDs.isEmpty {
            selectedIndex = 0
        }
    }

    private func makeLabel(for objectID: ObjectID, in plane: DesignPlane) -> String {
        guard let object = plane[objectID] else {
            return "\(objectID) (not found)"
        }
        let name: String = object["name"] ?? ""
        let display = name.isEmpty ? "" : " \(name)"
        return "\(objectID)\(display) — \(object.type.name)"
    }

    /// Truncate long values for display.
    private func truncatedValue(_ value: Variant) -> String {
        let str = String(describing: value)
        if str.count > 120 {
            return String(str.prefix(117)) + "..."
        }
        return str
    }
}

//
//  IssuesPanel.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 23/02/2026.
//

import CIimgui
import PoieticCore

// TODO: Review and improve the visuals

class IssuesPanel: Panel, WorkspaceBound {
    var isVisible: Bool = true
    weak var document: Document?
    weak var workspace: any WorkspaceServices?
//    var expandedObjects: Set<ObjectID> = []

    // TODO: Keep just objectID and get the name from the world
    weak var selectedObject: ObjectSnapshot? = nil
    var selectedIssueIndex: Int? = nil

    func bind(workspace: any WorkspaceServices, document: Document) {
        self.document = document
        self.workspace = workspace
    }
    func unbindWorkspace() {
        self.document = nil
        self.selectedObject = nil
        self.selectedIssueIndex = nil
    }
    
    func setSelectedObject(_ objectID: ObjectID? = nil) {
        if let objectID, let document {
            self.selectedObject = document.design.currentPlane?[objectID]
        }
        else {
            self.selectedObject = nil
            self.selectedIssueIndex = nil
        }
    }
    
    func update(_ timeDelta: Double) {
        // Nothing for now
    }
    
    func draw() {
        guard isVisible else { return }
        ImGui.Begin("Issues", &isVisible, ImGuiWindowFlags_None
                                        | ImGuiWindowFlags_AlwaysAutoResize)

        let tableFlags = ImGuiTableFlags_RowBg
                         | ImGuiTableFlags_BordersV
                         | ImGuiTableFlags_BordersOuterH
                         | ImGuiTableFlags_Resizable
                         | ImGuiTableFlags_SizingFixedFit
                         | ImGuiTableFlags_NoBordersInBody
        
        
        if ImGui.BeginTable("issues", 2, tableFlags, ImVec2()) {
            
            ImGui.TableSetupColumn("Message", ImGuiTableColumnFlags_None | ImGuiTableColumnFlags_WidthStretch)
//            ImGui.TableSetupColumn("Actions", ImGuiTableColumnFlags_None | ImGuiTableColumnFlags_WidthFixed)
//            ImGui.TableHeadersRow()

            if let issues = document?.world.issues {
                drawIssues(issues)
            }
            else {
                ImGui.TableNextRow()
                ImGui.TableNextColumn()
                ImGui.TextUnformatted("No issues")
            }
            
            ImGui.EndTable()
        }
        
        // Hints for selected issue (if any)
        if let issues = document?.world.issues,
           let selectedObject,
           let selectedIssueIndex,
           let objectIssues = issues[selectedObject.objectID],
           selectedIssueIndex < objectIssues.count
        {
            let issue = objectIssues[selectedIssueIndex]
            drawHints(issue: issue, for: selectedObject)
        }

        ImGui.End()
    }
    func drawIssues(_ issues: [ObjectID: [Issue]]) {
        guard let plane = document?.world.plane else { return }
        for (objectID, objectIssues) in issues {
            guard let object = plane[objectID] else { continue }
            drawObjectNode(object, issues: objectIssues)
        }
        
    }
    
    func drawObjectNode(_ object: ObjectSnapshot, issues: [Issue]) {
        let name = object.name ?? "(unnamed object)"
        let type = object.type.label
        let idString = object.objectID.stringValue
        let nodeLabel = "\(name) (\(type)) \(issues.count) issue(s)###\(idString)"

        let flags = ImGuiTreeNodeFlags_DefaultOpen.rawValue
                    | ImGuiTreeNodeFlags_LabelSpanAllColumns.rawValue

        ImGui.TableNextRow()
        ImGui.TableNextColumn()
        let open = ImGui.TreeNodeEx(nodeLabel, ImGuiTreeNodeFlags(ImGuiTreeNodeFlags_SpanAllColumns.rawValue | flags))

        if open {
            for (i, issue) in issues.enumerated() {
                ImGui.TableNextRow()
                ImGui.TableNextColumn()
                let message = issue.message // + "###" + String(i)
                ImGui.TreeNodeEx(message, ImGuiTreeNodeFlags(ImGuiTreeNodeFlags_SpanAllColumns.rawValue
                                                             | ImGuiTreeNodeFlags_Bullet.rawValue
                                                             | ImGuiTreeNodeFlags_Leaf.rawValue
                                                             | flags))
                if ImGui.IsItemClicked(0) {  // 0 = left mouse button
                    // Update selection
                    selectedObject = object
                    selectedIssueIndex = i

                    document?.changeSelection(.replaceAllWithOne(object.objectID))
                    workspace?.locateInView(object: object.objectID, zoom: nil)
                }
//                ImGui.TableNextColumn()
//                ImGui.TextUnformatted("(no action)")
                ImGui.TreePop()
            }
            
            ImGui.TreePop()

        }
    }
    func drawHints(issue: Issue, for object: ObjectSnapshot) {
        if ImGui.CollapsingHeader("Hints", ImGuiTreeNodeFlags(ImGuiTreeNodeFlags_None.rawValue)) {
            
            let name = object.name ?? "unnamed object"
            ImGui.TextUnformatted("Hints for \(name) (\(object.type.label))")
            ImGui.TextUnformatted("Issue: \(issue.message)")
            for hint in issue.hints {
                ImGui.Bullet()
                ImGui.TextWrappedUnformatted(hint)
            }
        }
    }
}

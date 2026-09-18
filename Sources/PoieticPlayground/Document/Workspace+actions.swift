//
//  Workspace+commands.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 14/09/2026.
//

import PoieticCore

extension Workspace {
    /// Handle workspace/document action.
    ///
    /// - Note: Handle only actions that do not present any decisions (dialogs, flows)
    ///
    @discardableResult
    func handleAction(_ action: Action) -> Bool {
        // NOTE: We are giving a chance for the caller to handle the action if we can not handle it
        switch action {
        // -- Tools --
        case .switchSelectionTool: toolBar.setTool(.selection)
        case .switchPlacementTool: toolBar.setTool(.placement)
        case .switchConnectTool: toolBar.setTool(.connect)
        case .switchPanTool:
            if let previousTool = toolBar.previousTool,
               toolBar.currentTool is PanTool
            {
                toolBar.setTool(previousTool)
            }
            else {
                toolBar.setTool(.pan)
            }
            
        // -- Edit --
        case .cut:
            guard let document = currentDocument  else { break }
            let ids: [ObjectID] = Array(document.selection.ids)
            copyToPasteboard(ids, from: document)
            document.enqueue(DeleteObjectsCommand(ids))

        case .copy:
            guard let document = currentDocument  else { break }
            let ids: [ObjectID] = Array(document.selection.ids)
            copyToPasteboard(ids, from: document)

        case .delete:
            guard let document = currentDocument  else { break }
            let ids: [ObjectID] = Array(document.selection.ids)
            document.enqueue(DeleteObjectsCommand(ids))

        case .paste:
            guard let document = currentDocument  else { break }
            guard let rawDesign = self.rawDesignFromPasteboard() else { break }
            document.enqueue(InsertObjectsCommand(rawDesign: rawDesign))

        case .undo:
            currentDocument?.enqueue(UndoCommand())
        case .redo:
            currentDocument?.enqueue(RedoCommand())
        case .selectAll: self.selectAll()
            
        // -- View ---
        case .toggleInspector:              inspector.isVisible.toggle()
        case .toggleIssuesPanel:            issuesPanel.isVisible.toggle()
        case .toggleDataTablePanel:         dataTablePanel.isVisible.toggle()
        case .toggleGraphicalFunctionPanel: graphicFunctionPanel.isVisible.toggle()
        case .toggleToolBar:                toolBar.isVisible.toggle()
        case .toggleDebugDesignPanel:       debugDesignPanel.isVisible.toggle()
        case .resetZoom:
            currentDocument?.enqueue(ResetZoomCommand(), canvas: canvas)
            
        // -- Inspector --
        case .overviewInspector:
            self.inspector.selectTab(.overview)
            self.inspector.isVisible = true
        case .propertiesInspector:
            self.inspector.selectTab(.properties)
            self.inspector.isVisible = true
            
        case .nameInlineEditor:      self.canvas.openInlineEditorForSelection("name")
        case .secondaryInlineEditor: self.canvas.openSecondaryInlineEditorForSelection()

        // Model
        case .autoConnectParameters: self.currentDocument?.autoConnectParameters()
        // Simulation
        case .runPlayer: self.player.run()
        case .stopPlayer: self.player.stop()
        default: return false
        }
        return true
    }

    func selectAll() {
        guard let document = currentDocument,
              let plane = document.world.plane
        else { return }

        let allIDs: [ObjectID] = plane.filter(trait: DiagramDomain.Traits.DiagramBlock).map {$0.objectID}
                                 + plane.filter(trait: DiagramDomain.Traits.DiagramConnector).map {$0.objectID}
        document.changeSelection(.replaceAll(allIDs))
    }
    
    func copyToPasteboard(_ ids: [ObjectID], from document: Document) {
        guard let text = document.serialiseForTextExport(ids: ids) else  {
            environment?.report(title: "Internal Error",
                                message: "Object serialisation failed",
                                style: .error)
            return
        }
        _ = environment?.setPasteboardText(text)
    }
    
    // TODO: Move to Document as rawDesignFromText/deserializeFromText
    func rawDesignFromPasteboard() -> RawDesign? {
        guard let text = environment?.getPasteboardText() else { return nil }
        guard let data = text.data(using: .utf8) else {
            environment?.report(title: "Error",
                                message: "Can not get pasteboard data",
                                style: .error)
        }

        let reader = JSONDesignReader()
        let rawDesign: RawDesign
        do {
            rawDesign = try reader.read(data: data)
        }
        catch {
            environment?.report(title: "Error",
                                message: "Unable to process pasteboard content: \(error.description)",
                                style: .error)

            return nil
        }
        return rawDesign
    }
    
}

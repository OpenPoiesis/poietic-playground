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
            guard let document = currentDocument else { break }
            let ids: [ObjectID] = Array(document.selection.ids)
            queueCommand(CutToPasteboardCommand(ids))
        case .copy:
            guard let document = currentDocument  else { break }
            let ids: [ObjectID] = Array(document.selection.ids)
            queueCommand(CopyToPasteboardCommand(ids))
        case .delete:
            guard let document = currentDocument  else { break }
            let ids: [ObjectID] = Array(document.selection.ids)
            queueCommand(DeleteObjectsCommand(ids))
        case .paste:
            queueCommand(PasteFromPasteboardCommand())
            
        case .undo: queueCommand(UndoCommand())
        case .redo: queueCommand(RedoCommand())
        case .selectAll: self.selectAll()
            
        // -- View ---
        case .toggleInspector:              inspector.isVisible.toggle()
        case .toggleIssuesPanel:            issuesPanel.isVisible.toggle()
        case .toggleDataTablePanel:         dataTablePanel.isVisible.toggle()
        case .toggleGraphicalFunctionPanel: graphicFunctionPanel.isVisible.toggle()
        case .toggleToolBar:                toolBar.isVisible.toggle()
        case .toggleDebugDesignPanel:       debugDesignPanel.isVisible.toggle()
        case .resetZoom:                    queueCommand(ResetZoomCommand())
            
        // -- Inspector --
        case .overviewInspector:
            self.inspector.selectTab(.overview)
            self.inspector.isVisible = true
        case .propertiesInspector:
            self.inspector.selectTab(.properties)
            self.inspector.isVisible = true
            
        case .nameInlineEditor:      self.canvas.openInlineEditorForSelection("name")
        case .secondaryInlineEditor: self.canvas.openSecondaryInlineEditorForSelection()

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
}

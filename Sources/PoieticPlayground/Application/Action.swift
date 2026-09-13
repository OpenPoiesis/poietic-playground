//
//  Action.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 13/09/2026.
//

enum Action: Hashable {
    // -- Tools --
    case switchSelectionTool
    case switchPlacementTool
    case switchConnectTool
    case switchPanTool
    
    // -- Application --
    case settings
    case quit

    // -- File --
    case new
    case open
    case save
    case saveAs
    case exportSVG

    // -- Edit --
    case cut
    case copy
    case paste
    case delete
    case undo
    case redo
    case selectAll

    // -- View ---
    case toggleInspector
    case toggleIssuesPanel
    case resetZoom

    // -- Inspector --
    case overviewInspector
    case propertiesInspector

    case nameInlineEditor
    case secondaryInlineEditor
    
    var name: String {
        switch self {
        case .switchSelectionTool: "switch_selection_tool"
        case .switchPlacementTool: "switch_placement_tool"
        case .switchConnectTool: "switch_connect_tool"
        case .switchPanTool: "switch_pan_tool"
        case .settings: "settings"
        case .quit: "quit"
        case .new: "new"
        case .open: "open"
        case .save: "save"
        case .saveAs: "save_as"
        case .exportSVG: "export_svg"
        case .cut: "cut"
        case .copy: "copy"
        case .paste: "paste"
        case .delete: "delete"
        case .undo: "undo"
        case .redo: "redo"
        case .selectAll: "select_all"
        case .toggleInspector: "toggle_inspector"
        case .toggleIssuesPanel: "toggle_issues_panel"
        case .resetZoom: "reset_zoom"
        case .overviewInspector: "overview_inspector"
        case .propertiesInspector: "properties_inspector"
        case .nameInlineEditor: "name_inline_editor"
        case .secondaryInlineEditor: "secondary_inline_editor"
        }
    }

}


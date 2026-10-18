//
//  Toolbar.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 31/01/2026.
//

import CIimgui

@MainActor
class Toolbar: @MainActor Panel {
    var isVisible: Bool = true
    
    private weak var toolManager: ToolManager?
    private let palette: ObjectPalette

    var traitEnvironment: TraitEnvironment
    
    init(toolManager: ToolManager, traitEnvironment: TraitEnvironment) {
        self.toolManager = toolManager
        self.traitEnvironment = traitEnvironment
        self.palette = ObjectPalette(columns: 3, items: [])
    }
    
    func update(_ timeDelta: Double) { }
    
    func draw() {
        guard let toolManager else { return }
        
        let buttonSize = ImVec2(32, 32)
        ImGui.Begin("##Tools", &isVisible, ImGuiWindowFlags_NoResize
                                        | ImGuiWindowFlags_NoScrollbar
                                        | ImGuiWindowFlags_NoCollapse)
        
        for (index, tool) in toolManager.tools.enumerated() {
            let toolClass = type(of: tool)
            let isActive = toolManager.isActive(tool)
            
            ImGui.PushID(Int32(index))

            ImGui.PushFont(nil, 32.0)
            if ImGui.IconButton(toolClass.iconKey,
                                id: toolClass.type.name,
                                tooltip: toolClass.type.name,
                                size: buttonSize,
                                pressed: isActive)
            {
                toolManager.select(toolClass.type)
            }
            ImGui.PopFont()
            ImGui.PopID()
            
            if index < toolManager.tools.count - 1 {
                ImGui.Spacing()
            }
        }
        
        let items = toolManager.activePaletteItems
        if !items.isEmpty {
            palette.setItems(items, selected: toolManager.selectedPaletteItem)
            if let selection = drawObjectPalette(palette) {
                toolManager.selectPaletteItem(selection)
            }
        }
        
        ImGui.End()
    }
    
    func drawObjectPalette(_ palette: ObjectPalette) -> String? {
        let paletteSpacing: Float = 0.0
        let toolbarPos = ImGui.GetWindowPos()
        let toolbarSize = ImGui.GetWindowSize()
        let palettePos = ImVec2(toolbarPos.x, toolbarPos.y + toolbarSize.y + paletteSpacing)

        ImGui.SetNextWindowPos(palettePos, 0, ImVec2())
        ImGui.Begin("##object-palette", nil,
                    ImGuiWindowFlags_AlwaysAutoResize
                    | ImGuiWindowFlags_NoScrollbar
                    | ImGuiWindowFlags_NoCollapse
                    | ImGuiWindowFlags_NoTitleBar
                    | ImGuiWindowFlags_NoSavedSettings)

        let selection = palette.draw()
        ImGui.End()
        return selection
    }
}

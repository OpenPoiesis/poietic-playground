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

    init(toolManager: ToolManager) {
        self.toolManager = toolManager
        self.palette = ObjectPalette(columns: 3, items: [])
    }
    
    func update(_ timeDelta: Double) { }
    
    func draw() {
        guard let toolManager else { return }
        let style = InterfaceStyle.current
        
        let buttonSize = ImVec2(32, 32)
        ImGui.Begin("Tools", &isVisible, ImGuiWindowFlags_NoResize
                                        | ImGuiWindowFlags_NoScrollbar
                                        | ImGuiWindowFlags_NoCollapse)
        
        for (index, tool) in toolManager.tools.enumerated() {
            let toolClass = type(of: tool)
            let isActive = toolManager.isActive(tool)
            
            if isActive {
                ImGui.PushStyleColor(ImGuiCol(ImGuiCol_Button.rawValue), ImVec4(0.7, 0.7, 0.7, 1.0))
                ImGui.PushStyleColor(ImGuiCol(ImGuiCol_ButtonHovered.rawValue), ImVec4(0.9, 0.9, 0.9, 1.0))
                ImGui.PushStyleColor(ImGuiCol(ImGuiCol_ButtonActive.rawValue), ImVec4(0.6, 0.6, 0.1, 1.0))
            }
            
            ImGui.PushID(Int32(index))

            let texture = style.texture(forIcon: toolClass.iconKey)
            let ref = ImTextureRef(texture.textureID)
            if ImGui.ImageButton("##\(toolClass.type.name)", ref, buttonSize, ImVec2(0, 0), ImVec2(1, 1), ImVec4(1, 1, 1, 0), ImVec4(1, 1, 1, 1)) {
                toolManager.select(toolClass.type)
            }
            ImGui.PopID()
            
            if ImGui.IsItemHovered(ImGuiHoveredFlags(ImGuiHoveredFlags_DelayShort.rawValue)) {
                ImGui.BeginTooltip()
                ImGui.TextUnformatted(toolClass.type.name)
                ImGui.EndTooltip()
            }
            
            if isActive {
                ImGui.PopStyleColor(3)
            }
            
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

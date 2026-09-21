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
            let isActive = toolManager.isActive(tool)
            
            if isActive {
                ImGui.PushStyleColor(ImGuiCol(ImGuiCol_Button.rawValue), ImVec4(0.7, 0.7, 0.7, 1.0))
                ImGui.PushStyleColor(ImGuiCol(ImGuiCol_ButtonHovered.rawValue), ImVec4(0.9, 0.9, 0.9, 1.0))
                ImGui.PushStyleColor(ImGuiCol(ImGuiCol_ButtonActive.rawValue), ImVec4(0.6, 0.6, 0.1, 1.0))
            }
            
            ImGui.PushID(Int32(index))

            let texture = style.texture(forIcon: tool.iconKey)
            let ref = ImTextureRef(texture.textureID)
            if ImGui.ImageButton("##\(tool.type.name)", ref, buttonSize, ImVec2(0, 0), ImVec2(1, 1), ImVec4(1, 1, 1, 0), ImVec4(1, 1, 1, 1)) {
                toolManager.select(tool.type)
            }
            ImGui.PopID()
            
            if ImGui.IsItemHovered(ImGuiHoveredFlags(ImGuiHoveredFlags_DelayShort.rawValue)) {
                ImGui.BeginTooltip()
                ImGui.TextUnformatted(tool.type.name)
                ImGui.EndTooltip()
            }
            
            if isActive {
                ImGui.PopStyleColor(3)
            }
            
            if index < toolManager.tools.count - 1 {
                ImGui.Spacing()
            }
        }
        
        if !toolManager.activePaletteItems.isEmpty {
            palette.setItems(toolManager.activePaletteItems)
            palette.select(toolManager.selectedPaletteItem)
            drawObjectPalette(palette)
        }
        
        ImGui.End()
    }
    
    func drawObjectPalette(_ palette: ObjectPalette) {
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

        palette.draw()
        ImGui.End()
    }
}

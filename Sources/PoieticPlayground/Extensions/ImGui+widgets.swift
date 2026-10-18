//
//  ImGui+widgets.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 07/10/2026.
//

import CIimgui

extension ImGui {
    /// Draw a button with an icon glyph.
    ///
    /// - SeeAlso: ``DrawIcon()``
    ///
    static func IconButton(_ iconKey: IconKey,
                           id: String,
                           tooltip: String? = nil,
                           size: ImVec2 = ImVec2(),
                           pressed: Bool = false) -> Bool {

        if pressed {
            let active = ImGui.GetStyleColor(ImGuiCol_ButtonActive).vectorValue
            ImGui.PushStyleColor(ImGuiCol_Button, color: Color(active))
        }

        let clicked = ImGui.Button("##\(id)", size)

        if pressed {
            ImGui.PopStyleColor()
        }
        
        DrawIconInItem(iconKey)
        
        if let tooltip, ImGui.IsItemHovered(ImGuiHoveredFlags(ImGuiHoveredFlags_DelayShort.rawValue))
        {
            ImGui.BeginTooltip()
            ImGui.TextUnformatted(tooltip)
            ImGui.EndTooltip()
        }

        return clicked
    }

    /// Draw an icon glyph with its ink centred on given position.
    ///
    /// - Parameters:
    ///     - key: Key of icon to be drawn.
    ///     - center: Position of the icon center.
    ///     - fontSize: size in actual pixels (the same convention as `ImDrawList.AddText`).
    ///                 If the value is 0 (default), then current font size is used.
    ///     - color: Drawing color. Defaults to style color of `ImGuiCol_Text`.
    ///     - drawList: `ImDrawList` to draw the icon into.
    ///
    /// - Returns: `false` if there is no icon glyph to draw (missing or blank glyph).
    ///
    /// - SeeAlso: ``IconKey/codepoint``, ``Application/IconFontPath``
    ///
    @discardableResult
    static func DrawIcon(_ key: IconKey,
                         center: ImVec2,
                         fontSize: Float = 0,
                         color: ImU32? = nil,
                         into drawList: UnsafeMutablePointer<ImDrawList>? = nil) -> Bool {

        let size = fontSize > 0 ? fontSize : ImGui.GetFontSize()

        // Swift makes some C++ functions returning a pointer as __NAMEUnsafe(...).
        // TODO: Review this on next ImGui or Swift version updates.
        guard let font = ImGui.GetFont(),
              let baked = font.pointee.__GetFontBakedUnsafe(size, -1.0),
              let glyph = baked.pointee.__FindGlyphUnsafe(key.codepoint),
              let list = drawList ?? ImGui.GetWindowDrawList()
        else { return false }

        // Skip blank glyphs.
        guard glyph.pointee.X1 > glyph.pointee.X0,
              glyph.pointee.Y1 > glyph.pointee.Y0
        else { return false }

        let pen = ImVec2(center.x - (glyph.pointee.X0 + glyph.pointee.X1) * 0.5,
                         center.y - (glyph.pointee.Y0 + glyph.pointee.Y1) * 0.5)

        let ink = color ?? ImGui.GetColorU32(ImGuiCol(ImGuiCol_Text.rawValue), 1.0)
        list.pointee.AddText(font, size, pen, ink, key.text)
        return true
    }
    
    @discardableResult
    static func DrawIconInItem(_ key: IconKey,
                               fontSize: Float = 0,
                               color: ImU32? = nil) -> Bool {
        let min = ImGui.GetItemRectMin()
        let max = ImGui.GetItemRectMax()
        return DrawIcon(key,
                        center: ImVec2((min.x + max.x) * 0.5, (min.y + max.y) * 0.5),
                        fontSize: fontSize,
                        color: color)
    }
}

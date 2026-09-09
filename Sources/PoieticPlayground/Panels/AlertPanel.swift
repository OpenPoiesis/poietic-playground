//
//  Alert.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 04/02/2026.
//

import CIimgui

class ConfirmationDialog: ModalDialog {
    static let DestructiveButtonColor = Color(red:0.8, green: 0.2, blue: 0.2)
    static let DestructiveButtonHoveredColor = Color(red: 1.0, green: 0.3, blue: 0.3)

    var status: ModalDialogStatus = .queued
    private var selectedOption: Int? = nil
    
    enum Emphasis {
        case neutral
        case primary
        case destructive
    }
    
    struct Option {
        let label: String
        let emphasis: Emphasis
        
        init(label: String, emphasis: Emphasis = .neutral) {
            self.label = label
            self.emphasis = emphasis
        }
    }

    let title: String
    let message: String
    let options: [Option]
    let completion: ((Int) -> Void)?
    
    init(title: String, message: String, options: [Option], completion: ((Int) -> Void)? = nil) {
        self.title = title
        self.message = message
        self.completion = completion
        self.options = options
    }
    
    func draw() {
//        ImGui.SetNextWindowSize(ImVec2(400, 0), ImGuiCond(ImGuiCond_Appearing.rawValue))
        ImGui.OpenPopup("##dialog_panel")
        if ImGui.BeginPopupModal("##dialog_panel"){
            ImGui.TextUnformatted(title)
            ImGui.Separator()
            ImGui.PushTextWrapPos(ImGui.GetCursorPosX() + 400)
               ImGui.TextUnformatted(message)
               ImGui.PopTextWrapPos()
            
//            ImGui.TextWrappedUnformatted(message)
            ImGui.Spacing()

            for (index, option) in options.enumerated() {
                ImGui.SameLine()
                if drawOptionButton(option) {
                    ImGui.CloseCurrentPopup()
                    selectedOption = index
                }
            }
            
            ImGui.EndPopup()
            
            if selectedOption != nil {
                self.status = .answered
            }
        }
    }
    
    func resolve() {
        guard self.status != .resolved,
              let selectedOption
        else { return }
        
        completion?(selectedOption)
        self.selectedOption = nil
    }
    
    func drawOptionButton(_ option: Option) -> Bool {
        switch option.emphasis {
        case .destructive:
            ImGui.PushStyleColor(ImGuiCol_Button, color: Self.DestructiveButtonColor)
            ImGui.PushStyleColor(ImGuiCol_ButtonHovered, color: Self.DestructiveButtonHoveredColor)
        case .neutral: break
        case .primary: break
        }

        let clicked = ImGui.Button(option.label, ImVec2(120, 0))
        
        switch option.emphasis {
        case .destructive:
            ImGui.PopStyleColor(2)
        case .neutral: break
        case .primary: break
        }

        return clicked
    }
}

//
//  Settings.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 19/02/2026.
//

import CIimgui

class SettingsPanel: Panel {
    weak var app: Application? = nil
    var interfaceStyle: InterfaceStyle? { app?.interfaceStyle }
    var isVisible: Bool = false
    var interfaceStyleSelection: Int32 = 0
    
    func bind(_ app: Application) {
        self.app = app
    }
    
    func draw() {
        guard isVisible else { return }
        ImGui.Begin("Settings", &isVisible, ImGuiWindowFlags_None | ImGuiWindowFlags_NoCollapse)
        drawInterfaceAppearanceSettings()
//        drawNotationSettings()
        ImGui.End()
    }
   
    func drawInterfaceAppearanceSettings() {
        let appearance: InterfaceStyle.Appearance
        if let app {
            appearance = app.interfaceStyle.appearance
        }
        else {
            appearance = .dark
        }
        
        ImGui.TextUnformatted("Appearance")
        ImGui.SameLine()
        if ImGui.RadioButton("Dark", appearance == .dark) {
            app?.setInterfaceAppearance(.dark)
        }
        ImGui.SameLine()
        if ImGui.RadioButton("Light", appearance == .light) {
            app?.setInterfaceAppearance(.light)
        }

    }
    
    func drawNotationSettings() {
        ImGui.SeparatorText("Notation")
    }
    
    func update(_ timeDelta: Double) {
    }
}

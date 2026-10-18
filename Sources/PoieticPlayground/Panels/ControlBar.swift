//
//  ControlBar.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 25/02/2026.
//

import CIimgui
import PoieticFlows
import PoieticCore

@MainActor
class ControlBar: @MainActor Panel {
    static let ButtonSize = ImVec2(32, 32)
    static let ButtonGroupOffset: Float = 20.0
    static let StepDisplayWidth: Float = 100.0
    
    var player: ResultPlayer? = nil
    var traitEnvironment: TraitEnvironment?
    var isEnabled: Bool = true
    var isVisible: Bool = true
    var currentStep: Int32 = 0
    var currentTime: Double = 0.0
    
    var settings: SimulationTimeSettings = SimulationTimeSettings()

    var currentStepBuffer: InputTextBuffer
    
    internal weak var document: Document? = nil
    
    init() {
        currentStepBuffer = InputTextBuffer("0")
    }

    func bind(_ player: ResultPlayer, traitEnvironment: TraitEnvironment) {
        self.player = player
        self.traitEnvironment = traitEnvironment
    }
    
    func unbind() {
        self.player = nil
    }
   
    func onDesignPlaneChanged(_ document: Document) {
        // We are assuming that simulation planning schedule was run.
        // Settings are set regardless whether we have a plan or not.
        self.settings = document.world.singleton() ?? SimulationTimeSettings()
        
        if let player {
            self.currentStep = Int32(player.currentStep)
            self.currentTime = player.currentTime
        }
        else {
            if currentStep >= settings.steps {
                currentStep = Int32(settings.steps)
            }
            self.currentTime = Double(currentStep) * settings.timeStep
        }
    }

    func onSimulationPlayerStep(_ document: Document) {
        guard let player else { return }
        self.currentStep = Int32(player.currentStep)
        self.currentTime = player.currentTime
    }
    
    func update(_ timeDelta: Double) {
        // Nothing for now
    }
    
    func draw() {
        ImGui.Begin("Simulation", &isVisible,
                                        ImGuiWindowFlags_NoResize
                                        | ImGuiWindowFlags_NoScrollbar
                                        | ImGuiWindowFlags_NoCollapse
                                        | ImGuiWindowFlags_AlwaysAutoResize)
        ImGui.BeginDisabled(!isEnabled)
        drawControlButtons()
        drawStepDisplay()
        drawTimeDisplay()

        ImGui.PushItemWidth(ImGui.GetContentRegionAvail().x)

        let previousStep = currentStep
        ImGui.SliderInt("##current_step_slider", &currentStep, 0, Int32(settings.steps), "")
        if currentStep != previousStep {
            self.player?.setCurrentStep(Int(currentStep))
        }

        ImGui.EndDisabled()
        ImGui.End()
    }
    
    func drawControlButtons() {
        
        ImGui.BeginGroup()

        if controlButton("Run", iconKey: .run, isPressed: self.player?.isRunning ?? false) {
            self.player?.run()
        }
        ImGui.SameLine()
        if controlButton("Stop", iconKey: .stop) {
            self.player?.stop()
        }
        ImGui.SameLine(0, Self.ButtonGroupOffset)

        if controlButton("Beginning", iconKey: .restart) {
            self.player?.toFirstStep()
        }
        ImGui.SameLine()
        if controlButton("Previous", iconKey: .previousStep) {
            self.player?.previousStep()
        }
        ImGui.SameLine()
        if controlButton("Next", iconKey: .nextStep) {
            self.player?.nextStep()
        }
        ImGui.SameLine()
        if controlButton("End", iconKey: .lastStep) {
            self.player?.toLastStep()
        }
        ImGui.SameLine()
        ImGui.SameLine(0, Self.ButtonGroupOffset)
        if controlButton("Loop", iconKey: .loop) {
            
        }

        ImGui.EndGroup()
        

    }
    
    func drawStepDisplay() {
        let inputFlags: ImGuiInputTextFlags = ImGuiInputTextFlags_None
                            | ImGuiInputTextFlags_CharsDecimal
                            | ImGuiInputTextFlags_CharsNoBlank

        let imStyle = ImGui.GetStyle().pointee
        let titleFontSize = imStyle.FontSizeBase * 2
        ImGui.SameLine()
        ImGui.BeginGroup()
        ImGui.PushFont(nil, titleFontSize)
        ImGui.SetNextItemWidth(Self.StepDisplayWidth)

        let previousStep = currentStep
        ImGui.InputInt("##current_step", &currentStep, 0, 0, 0)
        if currentStep != previousStep {
            player?.setCurrentStep(Int(currentStep))
        }

        ImGui.PopFont()
        ImGui.TextUnformatted("step")
        ImGui.EndGroup()
    }
    
    func drawTimeDisplay() {
        let inputFlags: ImGuiInputTextFlags = ImGuiInputTextFlags_None
                            | ImGuiInputTextFlags_CharsDecimal
                            | ImGuiInputTextFlags_CharsNoBlank

        let imStyle = ImGui.GetStyle().pointee
        let titleFontSize = imStyle.FontSizeBase * 2
        ImGui.SameLine()
        ImGui.BeginGroup()
        ImGui.PushFont(nil, titleFontSize)
        ImGui.SetNextItemWidth(Self.StepDisplayWidth)

        let previousTime = currentTime
        ImGui.InputDouble("##current_time", &currentTime, 0, 0, "%0.2f")

        if currentTime != previousTime {
            self.player?.setCurrentTime(currentTime)
        }

        ImGui.PopFont()
        ImGui.TextUnformatted("time")
        ImGui.EndGroup()
    }

    func controlButton(_ label: String, iconKey: IconKey, isPressed: Bool = false) -> Bool {
        let result: Bool

        ImGui.PushFont(nil, 28.0)
        result = ImGui.IconButton(iconKey,
                                  id: label,
                                  tooltip: label,
                                  size: Self.ButtonSize,
                                  pressed: isPressed)
        ImGui.PopFont()
        return result
    }
}

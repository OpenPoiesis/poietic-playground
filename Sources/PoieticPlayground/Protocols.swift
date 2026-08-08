//
//  Protocols.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 05/02/2026.
//
import CIimgui

@MainActor
protocol ApplicationObject {
    func update(_ timeDelta: Double)
}

protocol View: ApplicationObject {
    func draw()
}

protocol Controller: ApplicationObject {
    func processInput(_ io: ImGuiIO)
}
extension Controller {
    func processInput(_ io: ImGuiIO) {}
}

protocol Panel: View {
    /// Flag whether the panel is visible.
    ///
    /// If panel is not visible it will not be drawn: the ``View/draw()`` method will not be called.
    var isVisible: Bool { get set }
    
    /// Handle an action with given name.
    ///
    /// Default implementation returns `false.`
    ///
    /// - Returns: `true` if the action was handled, otherwise `false`.
    func handleAction(_ actionName: String) -> Bool
}

extension Panel {
    func handleAction(_ actionName: String) -> Bool {
        return false
    }
}

//
//  ModalDialog.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 09/09/2026.
//

enum ModalDialogStatus {
    case queued
    case active
    case answered
    case resolved
}

@MainActor
protocol ModalDialog: AnyObject {
    var status: ModalDialogStatus { get set }
    /// Draw the modal. Must NOT mutate application state; only record the answer.
    func draw()

    /// Run the completion for the recorded answer. Called once by the manager,
    /// during update(), never during draw().
    func resolve()
}

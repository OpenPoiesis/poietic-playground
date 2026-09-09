//
//  Application+modal.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 09/09/2026.
//

import CIimgui

extension Application {
    func queueDialog(_ dialog: any ModalDialog) {
        modalQueue.append(dialog)
    }
    
    func updateDialogs() {
        for dialog in modalQueue where dialog.status == .answered {
            dialog.resolve()
            dialog.status = .resolved
        }
        
        modalQueue.removeAll { $0.status == .resolved }
        
        if let first = modalQueue.first(where: { $0.status == .queued}) {
            first.status = .active
        }
    }
}

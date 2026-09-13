//
//  Application+modal.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 09/09/2026.
//

import CIimgui

extension Application {
    func openFileSelector(title: String,
                          mode: FileSelectionMode = .open,
                          filter: String? = nil,
                          callback: @escaping ((String?) -> Void))
    {
        // TODO: Instantiate new file picker here. We need a mechanism of preserving last picker directory.
        let dialog = FileSelectionDialog(
            title: title,
            mode: mode,
            filter: filter ?? "*"
        ) { [weak self] selectedPath in
            guard let self else { return }
            
            if let selectedPath,
               let path = FileSelectionDialog.directoryIfExists(from: selectedPath)
            {
                self.lastFilePickerDirectory = path
            }
            callback(selectedPath)
        }
        queueDialog(dialog)
    }
    
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

//
//  Application+modal.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 09/09/2026.
//

import CIimgui

extension Application {
    func openFilePicker(title: String,
                        mode: FilePickerMode = .open,
                        filter: String? = nil,
                        callback: @escaping ((String) -> Void))
    {
        // TODO: Instantiate new file picker here. We need a mechanism of preserving last picker directory.
        let filePicker = FilePickerPanel(
            title: title,
            mode: mode,
            filter: filter ?? "*"
        ) { [weak self] selectedPath in
            guard let self else { return }
            
            if let path = FilePickerPanel.directoryIfExists(from: selectedPath) {
                self.lastFilePickerDirectory = path
            }
            callback(selectedPath)
        }
        queueDialog(filePicker)
    }
    
    func queueDialog(_ dialog: any ModalDialog) {
        print("QUEUED DIALOG: \(dialog)")
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

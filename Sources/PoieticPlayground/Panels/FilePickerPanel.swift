//
//  FilePickerPanel.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 23/03/2026.
//

import CIimgui
import Cimguifd
import Foundation

class FilePickerPanel: ModalDialog {
    /// Returns a directory path that exists in the filesystem given a file path.
    ///
    /// If the path is a directory, then the directory is tested for existence. If the path
    /// is a file, then the file is stripped and it's directory is tested for existence. If neither
    /// exists then `nil` is returned.
    ///
    static func directoryIfExists(from path: String) -> String? {
        var result: String? = nil
        var isDir: ObjCBool = false
        let fm = FileManager()
        
        if fm.fileExists(atPath: path, isDirectory: &isDir) && isDir.boolValue {
            result = path
        }
        else {
            let url = URL(fileURLWithPath: path)
            let trimmed = url.deletingLastPathComponent().path
            if fm.fileExists(atPath: trimmed, isDirectory: &isDir) && isDir.boolValue {
                result = trimmed
            }
        }
        return result
    }

    
    var status: ModalDialogStatus = .queued

    var title: String
    var mode: ImGuiFDMode
    var filter: String?
    var path: String
    var callback: ((String?) -> Void)? = nil
    var isOpen: Bool = false
    
    /// Path selected by the user, or `nil` if user cancelled or when the panel is not active.
    var selectedPath: String?
    
    
    /// Create a new file-picker
    ///
    /// - Parameters:
    ///     - title: Title of the file picker, for example `"Save Document"`
    ///     - mode: Mode of selection - opening a file or saving a file (can have a new name)
    ///     - filter: Patter for selectable files.
    ///     - path: Path where the file picker should be opened.
    ///     - callback: Closure to call when file picker is finished. The argument is `nil` if
    ///       the user cancels the selection or dismisses the panel.
    ///
    init(title: String = "Select File",
         mode: FilePickerMode = .open,
         filter: String = "*",
         path: String = ".",
         callback: ((String?) -> Void)? = nil)
    {
        self.title = title
        self.filter = filter
        self.path = path
        self.callback = callback
        self.status = .queued
        
        switch mode {
        case .open: self.mode = ImGuiFDMode(ImGuiFDMode_LoadFile)
        case .save: self.mode = ImGuiFDMode(ImGuiFDMode_SaveFile)
        case .openDirectory: self.mode = ImGuiFDMode(ImGuiFDMode_OpenDir)
        }
    }
    
    func draw() {
        guard status == .active else { return }

        let id = "\(title)###file_picker_panel"
        
        if !isOpen {
            ImGuiFD.OpenDialog(id,
                               mode,
                               path,
                               filter,
                               ImGuiFDDialogFlags(ImGuiFDDialogFlags_Modal))
            isOpen = true
        }
        
        var path: String? = nil
        
        if ImGuiFD.BeginDialog(id) {
            if ImGuiFD.ActionDone() {
                if ImGuiFD.SelectionMade(),
                   let pathPtr: UnsafePointer<CChar> = ImGuiFD.GetSelectionPathString(0)
                {
                    path = String(cString: pathPtr)
                }
                ImGuiFD.CloseCurrentDialog()
                isOpen = false
                selectedPath = path
                status = .answered
            }

            ImGuiFD.EndDialog()
        }
    }

    func resolve() {
        guard self.status == .answered else { return }
        self.status = .resolved
        callback?(selectedPath)
    }
}


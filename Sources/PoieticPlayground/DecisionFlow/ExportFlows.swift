//
//  ExportFlows.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 13/09/2026.
//

import Foundation

final class ChoosePathForWritingFlow: DecisionFlow {
    private let context: DecisionFlowContext
    private let title: String
    private let fileExtension: String
    
    private(set) var selectedURL: URL? = nil
    
    init(context: DecisionFlowContext, title: String, fileExtension: String) {
        self.title = title
        self.context = context
        self.fileExtension = fileExtension
    }
    
    func start() {
        context.presentFileSelector(title: title,
                                    mode: .save,
                                    filter: "*." + fileExtension,
                                    completion: self.pathSelected)
    }
    
    func pathSelected(selectedPath: String?) {
        guard let selectedPath else {
            context.finish(self, outcome: .cancelled)
            return
        }
        
        let url = Document.normalizePathExtension(URL(fileURLWithPath: selectedPath),
                                                  extension: fileExtension)
        
        guard FileManager.default.fileExists(atPath: url.path) else {
            self.selectedURL = url
            context.finish(self, outcome: .success)
            return
        }
        confirmOverwrite(url: url)
    }
    
    func confirmOverwrite(url: URL) {
        context.presentDecision(
            title: "File Exists",
            message: "'\(url.lastPathComponent)' already exists. Overwrite?",
            choices: [
                DecisionFlowChoice("Cancel") {
                    self.context.finish(self, outcome: .cancelled)
                },
                DecisionFlowChoice("Overwrite", emphasis: .destructive) {
                    self.selectedURL = url
                    self.context.finish(self, outcome: .success)
                }
            ]
        )
    }
}

final class ExportSVGFlow: DecisionFlow {
    let context: DecisionFlowContext

    init(context: DecisionFlowContext) {
        self.context = context
    }
    
    func start() {
        let choosePath = ChoosePathForWritingFlow(context: context, title: "Export SVG", fileExtension: "svg")
        context.startSubflow(choosePath) { [weak self] outcome in
            guard let self else { return }

            switch outcome {
            case .success:
                guard let url = choosePath.selectedURL else {
                    self.context.finish(self, outcome: .cancelled)
                    break
                }
                self.export(to: url)
            case .cancelled, .failure:
                self.context.finish(self, outcome: outcome)
            }
        }
    }
    func export(to url: URL) {
        guard let document = context.document else { return }
        let command = ExportSVGCommand(url: url, appendExtensionIfNeeded: true)
        do {
            try context.execute(command, document: document)
            self.context.finish(self, outcome: .success)
        }
        catch {
            self.context.presentMessage(title: "Export Failed", message: error.message, style: .error)
            self.context.finish(self, outcome: .failure)
        }
    }
}

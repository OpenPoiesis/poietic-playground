//
//  ExportFlows.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 13/09/2026.
//

import Foundation

final class ChoosePathForWritingFlow: DecisionFlow {
    private weak let context: (any DecisionFlowContext)?
    private let title: String
    private let fileExtension: String
    
    private(set) var selectedURL: URL? = nil
    
    init(context: any DecisionFlowContext, title: String, fileExtension: String) {
        self.title = title
        self.context = context
        self.fileExtension = fileExtension
    }
    
    func start() {
        guard let context else { return }
        context.presentFileSelector(title: title,
                                    mode: .save,
                                    filter: "*." + fileExtension,
                                    completion: self.pathSelected)
    }
    
    func pathSelected(selectedPath: String?) {
        guard let context else { return }
        guard let selectedPath else {
            context.finish(self, outcome: .cancelled)
            return
        }
        
        let url = Document.normalisePathExtension(URL(fileURLWithPath: selectedPath),
                                                  extension: fileExtension)
        
        guard FileManager.default.fileExists(atPath: url.path) else {
            self.selectedURL = url
            context.finish(self, outcome: .success)
            return
        }
        confirmOverwrite(url: url)
    }
    
    func confirmOverwrite(url: URL) {
        guard let context else { return }
        context.presentDecision(
            title: "File Exists",
            message: "'\(url.lastPathComponent)' already exists. Overwrite?",
            choices: [
                DecisionFlowChoice("Cancel") {
                    context.finish(self, outcome: .cancelled)
                },
                DecisionFlowChoice("Overwrite", emphasis: .destructive) {
                    self.selectedURL = url
                    context.finish(self, outcome: .success)
                }
            ]
        )
    }
}

final class ExportSVGFlow: DecisionFlow {
    weak let context: (any DecisionFlowContext)?

    init(context: any DecisionFlowContext) {
        self.context = context
    }
    
    func start() {
        guard let context else { return }
        
        let choosePath = ChoosePathForWritingFlow(context: context, title: "Export SVG", fileExtension: "svg")
        context.presentSubflow(choosePath) { [weak self] outcome in
            guard let self else { return }

            switch outcome {
            case .success:
                guard let url = choosePath.selectedURL else {
                    context.finish(self, outcome: .cancelled)
                    break
                }
                self.export(to: url)
            case .cancelled, .failure:
                context.finish(self, outcome: outcome)
            }
        }
    }
    func export(to url: URL) {
        guard let context else { return }
        
        let command = ExportSVGCommand(url: url, appendExtensionIfNeeded: true)
        do {
            try context.execute(command)
            context.finish(self, outcome: .success)
        }
        catch {
            context.presentMessage(title: "Export Failed", message: error.message, style: .error)
            context.finish(self, outcome: .failure)
        }
    }
}

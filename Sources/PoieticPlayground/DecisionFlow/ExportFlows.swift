//
//  ExportFlows.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 13/09/2026.
//

import Foundation

// TODO: Extract present selector -> check for existence -> confirm overwrite to a single. Requires path outcome

final class ExportSVGFlow: DecisionFlow {
    weak let context: (any DecisionFlowContext)?

    init(context: any DecisionFlowContext) {
        self.context = context
    }
    
    func start() {
        guard let context else { return }
        context.presentFileSelector(title: "Export SVG",
                                    mode: .save,
                                    filter: "*.svg",
                                    completion: self.pathSelected)
    }
    
    func pathSelected(selectedPath: String?) {
        guard let context else { return }
        
        guard let selectedPath else {
            context.finish(self, outcome: .cancelled)
            return
        }
        
        let url = Document.normalisePathExtension(URL(fileURLWithPath: selectedPath), extension: "svg")
        
        if FileManager.default.fileExists(atPath: url.path) {
            self.confirmOverwrite(url: url)
        }
        else {
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
                    let outcome = saveDocument(to: url, context: context)
                    context.finish(self, outcome: outcome)
                }
            ]
        )
    }
}

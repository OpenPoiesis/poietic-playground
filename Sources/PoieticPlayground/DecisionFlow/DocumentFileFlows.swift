//
//  SaveFlows.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 11/09/2026.
//

import Foundation

@MainActor
func saveDocument(to url: URL, context: any DecisionFlowContext) -> DecisionFlowOutcome {
    let command = SaveDesignCommand(url: url, appendExtensionIfNeeded: true)
    do {
        try context.execute(command)
        return .success
    }
    catch {
        context.presentMessage(title: "Save Failed", message: error.message, style: .error)
        return .failure
    }
}

/// Save document to a file selected by a file selector.
///
final class SaveDocumentWithFileSelectionFlow: DecisionFlow {
    weak let context: (any DecisionFlowContext)?

    init(context: any DecisionFlowContext) {
        self.context = context
    }
    
    func start() {
        guard let context else { return }
        context.presentFileSelector(title: "Save Document To",
                                  mode: .save,
                                  filter: "*." + Document.FileExtension,
                                  completion: self.pathSelected)
    }
    
    func pathSelected(selectedPath: String?) {
        guard let context else { return }
        
        guard let selectedPath else {
            context.finish(self, outcome: .cancelled)
            return
        }
        
        let url = Document.normalisePathExtension(URL(fileURLWithPath: selectedPath))
        
        if FileManager.default.fileExists(atPath: url.path) {
            self.confirmOverwrite(url: url)
        }
        else {
            let outcome = saveDocument(to: url, context: context)
            context.finish(self, outcome: outcome)
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


final class SaveDocumentFlow: DecisionFlow {
    weak let context: (any DecisionFlowContext)?

    init(context: any DecisionFlowContext) {
        self.context = context
    }

    func start() {
        guard let context else { return }
        
        if let url = context.document?.designURL {
            let outcome = saveDocument(to: url, context: context)
            context.finish(self, outcome: outcome)
        }
        else {
            let subflow = SaveDocumentWithFileSelectionFlow(context: context)

            context.presentSubflow(subflow) { outcome in
                context.finish(self, outcome: outcome)
            }
        }
    }
}

final class SaveDocumentIfNeededFlow: DecisionFlow {
    weak let context: (any DecisionFlowContext)?

    init(context: any DecisionFlowContext) {
        self.context = context
    }

    func start() {
        guard let context else { return }
        guard let document = context.document else {
            context.finish(self, outcome: .failure)
            return
        }
        
        guard document.hasUnsavedChanges else {
            context.finish(self, outcome: .success)
            return
        }

        context.presentDecision(
            title: "Unsaved Changes",
            message: "Design contains unsaved changes. Do you want to save or discard them?",
            choices: [
                DecisionFlowChoice("Cancel") {
                    context.finish(self, outcome: .cancelled)
                },
                DecisionFlowChoice("Save") {
                    self.saveDocument()
                },
                DecisionFlowChoice("Discard Changes", emphasis: .destructive) {
                    context.finish(self, outcome: .success)
                }
            ]
        )
    }
    
    func saveDocument() {
        guard let context else { return }
        
        context.presentSubflow(SaveDocumentFlow(context: context)) { outcome in
            context.finish(self, outcome: outcome)
        }
    }
}


// Called on: menu -> open; Cmd+O shortcut or file drop (we need to specify URL somehow)
final class OpenDocumentWithFileSelectionFlow: DecisionFlow {
    weak let context: (any DecisionFlowContext)?

    init(context: any DecisionFlowContext) {
        self.context = context
    }

    func start() {
        guard let context else { return }
        
        let subflow = SaveDocumentIfNeededFlow(context: context)
        
        context.presentSubflow(subflow) { [weak self] outcome in
            guard let self else { return }
            switch outcome {
            case .success:
                self.selectDocumentFile()
            case .cancelled, .failure:
                context.finish(self, outcome: .cancelled)
            }
        }
    }
    
    func selectDocumentFile() {
        guard let context else { return }
        
        context.presentFileSelector(title: "Open Document",
                                  mode: .open,
                                  filter: "*." + Document.FileExtension)
        { [weak self] selectedPath in
            guard let self else { return }
            guard let selectedPath else {
                context.finish(self, outcome: .cancelled)
                return
            }
            
            let url = URL(fileURLWithPath: selectedPath)
            self.open(from: url)
        }

    }
    
    func open(from url: URL) {
        guard let context else { return }
        let command = OpenDesignCommand(url: url)
        do {
            try context.execute(command)
            context.finish(self, outcome: .success)
        }
        catch {
            context.presentMessage(title: "Open Failed", message: error.message, style: .error)
            context.finish(self, outcome: .failure)
        }
    }
}

final class OpenDocumentFromURLFlow: DecisionFlow {
    weak let context: (any DecisionFlowContext)?
    let url: URL

    init(context: any DecisionFlowContext, url: URL) {
        self.context = context
        self.url = url
    }

    func start() {
        guard let context else { return }
        
        let subflow = SaveDocumentIfNeededFlow(context: context)

        context.presentSubflow(subflow) { [weak self] outcome in
            guard let self else { return }
            switch outcome {
            case .success:
                self.open(from: self.url)
            case .cancelled, .failure:
                context.finish(self, outcome: .cancelled)
            }
        }
    }
    
    func open(from url: URL) {
        guard let context else { return }
        let command = OpenDesignCommand(url: url)
        do {
            try context.execute(command)
            context.finish(self, outcome: .success)
        }
        catch {
            context.presentMessage(title: "Open Failed", message: error.message, style: .error)
            context.finish(self, outcome: .failure)
        }
    }
}

final class QuitApplicationFlow: DecisionFlow {
    weak let context: (any DecisionFlowContext)?

    init(context: any DecisionFlowContext) {
        self.context = context
    }

    func start() {
        guard let context else { return }

        let subflow = SaveDocumentIfNeededFlow(context: context)

        context.presentSubflow(subflow) { [weak self] completion in
            guard let self else { return }
            
            guard completion == .success else {
                context.finish(self, outcome: .cancelled)
                return
            }
                
            do {
                try context.execute(QuitApplicationCommand())
                context.finish(self, outcome: .success)
            }
            catch {
                context.presentMessage(title: "Quit", message: error.localizedDescription, style: .error)
                context.finish(self, outcome: .failure)
            }
        }

        // TODO: Implement
        // 1. Sub-flow: SaveDocumentIfNeededFlow
        // 2. Flag application as "quit requested"
        
    }
}

final class NewDesignFlow: DecisionFlow {
    weak let context: (any DecisionFlowContext)?

    init(context: any DecisionFlowContext) {
        self.context = context
    }

    func start() {
        guard let context else { return }
        
        let subflow = SaveDocumentIfNeededFlow(context: context)

        context.presentSubflow(subflow) { [weak self] outcome in
            guard let self else { return }
            switch outcome {
            case .success:
                do {
                    try context.execute(NewDesignCommand())
                    context.finish(self, outcome: .success)
                }
                catch {
                    context.presentMessage(title: "New Design", message: error.localizedDescription, style: .error)
                    context.finish(self, outcome: .failure)
                }
            case .cancelled, .failure:
                context.finish(self, outcome: .cancelled)
            }
        }
    }
}


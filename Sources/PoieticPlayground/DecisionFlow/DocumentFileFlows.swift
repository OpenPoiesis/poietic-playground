//
//  DocumentFileFlows.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 11/09/2026.
//

import Foundation

@MainActor
func saveDocument(_ document: Document, to url: URL, context: DecisionFlowContext) -> DecisionFlowOutcome {
    let normalizedURL = Document.normalizePathExtension(url)

    do {
        try document.save(to: normalizedURL)
        return .success
    }
    catch {
        context.environment?.report(title: "Save Failed", message: error.description, style: .error)
        return .failure
    }
}

@MainActor
func openDocument(from url: URL, context: DecisionFlowContext) -> DecisionFlowOutcome{
    do {
        try context.workspace?.openDesign(url: url)
        return .success
    }
    catch {
        context.environment?.report(title: "Open Failed", message: error.description, style: .error)
        return .failure
    }
}


/// Save document to a file selected by a file selector.
///
final class SaveDocumentWithFileSelectionFlow: DecisionFlow {
    let context: DecisionFlowContext
    weak let document: Document?

    init(context: DecisionFlowContext, document: Document) {
        self.context = context
        self.document = document
    }
    
    func start() {
        context.presentFileSelector(title: "Save Document To",
                                    mode: .save,
                                    filter: "*." + Document.FileExtension,
                                    completion: self.pathSelected)
    }
    
    func pathSelected(selectedPath: String?) {
        guard let document else {
            context.finish(self, outcome: .cancelled)
            return
        }
        guard let selectedPath else {
            context.finish(self, outcome: .cancelled)
            return
        }
        
        let url = Document.normalizePathExtension(URL(fileURLWithPath: selectedPath))
        
        if FileManager.default.fileExists(atPath: url.path) {
            self.confirmOverwrite(url: url)
        }
        else {
            let outcome = saveDocument(document, to: url, context: context)
            context.finish(self, outcome: outcome)
        }
    }
    
    func confirmOverwrite(url: URL) {
        guard let document else {
            context.finish(self, outcome: .cancelled)
            return
        }

        context.presentDecision(
            title: "File Exists",
            message: "'\(url.lastPathComponent)' already exists. Overwrite?",
            choices: [
                DecisionFlowChoice("Cancel") {
                    self.context.finish(self, outcome: .cancelled)
                },
                DecisionFlowChoice("Overwrite", emphasis: .destructive) {
                    let outcome = saveDocument(document, to: url, context: self.context)
                    self.context.finish(self, outcome: outcome)
                }
            ]
        )
    }
}


final class SaveDocumentFlow: DecisionFlow {
    let context: DecisionFlowContext
    weak let document: Document?

    init(context: DecisionFlowContext, document: Document) {
        self.context = context
        self.document = document
    }

    func start() {
        guard let document else {
            context.finish(self, outcome: .cancelled)
            return
        }

        if let url = document.designURL {
            let outcome = saveDocument(document, to: url, context: context)
            context.finish(self, outcome: outcome)
        }
        else {
            let subflow = SaveDocumentWithFileSelectionFlow(context: context, document: document)

            context.startSubflow(subflow) { outcome in
                self.context.finish(self, outcome: outcome)
            }
        }
    }
}

final class SaveDocumentIfNeededFlow: DecisionFlow {
    let context: DecisionFlowContext
    weak let document: Document?

    init(context: DecisionFlowContext, document: Document) {
        self.context = context
        self.document = document
    }

    func start() {
        guard let document else {
            context.finish(self, outcome: .cancelled)
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
                    self.context.finish(self, outcome: .cancelled)
                },
                DecisionFlowChoice("Save") {
                    self.saveDocument()
                },
                DecisionFlowChoice("Discard Changes", emphasis: .destructive) {
                    self.context.finish(self, outcome: .success)
                }
            ]
        )
    }
    
    func saveDocument() {
        guard let document else {
            context.finish(self, outcome: .cancelled)
            return
        }

        context.startSubflow(SaveDocumentFlow(context: context, document: document)) { outcome in
            self.context.finish(self, outcome: outcome)
        }
    }
}


// Called on: menu -> open; Cmd+O shortcut or file drop (we need to specify URL somehow)
final class OpenDocumentWithFileSelectionFlow: DecisionFlow {
    let context: DecisionFlowContext

    init(context: DecisionFlowContext) {
        self.context = context
    }

    func start() {
        if let document = context.workspace?.currentDocument {
            let subflow = SaveDocumentIfNeededFlow(context: context, document: document)
            
            context.startSubflow(subflow) { [weak self] outcome in
                guard let self else { return }
                switch outcome {
                case .success:
                    self.selectDocumentFile()
                case .cancelled, .failure:
                    self.context.finish(self, outcome: .cancelled)
                }
            }
        }
        else {
            self.selectDocumentFile()
        }
    }
    
    func selectDocumentFile() {
        context.presentFileSelector(title: "Open Document",
                                  mode: .open,
                                  filter: "*." + Document.FileExtension)
        { [weak self] selectedPath in
            guard let self else { return }
            guard let selectedPath else {
                self.context.finish(self, outcome: .cancelled)
                return
            }
            
            let url = URL(fileURLWithPath: selectedPath)
            let outcome = openDocument(from: url, context: context)
            self.context.finish(self, outcome: outcome)
        }

    }
    
    func open(from url: URL) {
        do {
            try context.workspace?.openDesign(url: url)
            context.finish(self, outcome: .success)
        }
        catch {
            context.environment?.report(title: "Open Failed", message: error.description, style: .error)
            context.finish(self, outcome: .failure)
        }
    }
}

final class OpenDocumentFromURLFlow: DecisionFlow {
    let context: DecisionFlowContext
    let url: URL

    init(context: DecisionFlowContext, url: URL) {
        self.context = context
        self.url = url
    }

    func start() {
        if let document = context.workspace?.currentDocument {
            let subflow = SaveDocumentIfNeededFlow(context: context, document: document)
            
            context.startSubflow(subflow) { [weak self] outcome in
                guard let self else { return }
                switch outcome {
                case .success:
                    let outcome = openDocument(from: url, context: context)
                    self.context.finish(self, outcome: outcome)
                case .cancelled, .failure:
                    self.context.finish(self, outcome: .cancelled)
                }
            }
        }
        else {
            let outcome = openDocument(from: url, context: context)
            self.context.finish(self, outcome: outcome)
        }
    }
}

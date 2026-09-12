//
//  SaveFlows.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 11/09/2026.
//

import Foundation

/// Save document to a file selected by a file selector.
///
final class SaveDocumentWithFileSelectionFlow: DecisionFlow {
    weak let context: (any DecisionFlowContext)?
    let completion: ((DecisionFlowOutcome) -> Void)?

    init(context: any DecisionFlowContext, completion: ((DecisionFlowOutcome)->Void)? = nil) {
        self.context = context
        self.completion = completion
    }
    
    func start() {
        guard let context else { return }
        context.presentFilePicker(title: "Save Document To",
                                  mode: .save,
                                  filter: "*." + Document.FileExtension,
                                  completion: self.pathSelected)
    }
    
    func pathSelected(selectedPath: String?) {
        guard let selectedPath else {
            self.finish(.cancelled)
            return
        }
        
        let url = URL(fileURLWithPath: selectedPath)
        
        if FileManager.default.fileExists(atPath: url.path) {
            self.confirmOverwrite(url: url)
        }
        else {
            self.save(to: url)
        }
    }
    
    func confirmOverwrite(url: URL) {
        guard let context else { return }
        context.presentDecision(
            title: "File Exists",
            message: "'\(url.lastPathComponent)' already exists. Overwrite?",
            choices: [
                DecisionFlowChoice("Cancel") {
                    self.finish(.cancelled)
                },
                DecisionFlowChoice("Overwrite", emphasis: .destructive) {
                    self.save(to: url)
                }
            ]
        )
    }
    
    func save(to url: URL) {
        guard let context else { return }
        let command = SaveDesignCommand(url: url, appendExtensionIfNeeded: true)
        do {
            try context.execute(command)
            finish(.success)
        }
        catch {
            context.presentMessage(title: "Save Failed", message: error.message, style: .error)
            finish(.failure)
        }
    }
    
    func finish(_ outcome: DecisionFlowOutcome) {
        guard let context else { return }
        if context.finish(self) {
            completion?(outcome)
        }
    }
}


final class SaveDocumentFlow: DecisionFlow {
    weak let context: (any DecisionFlowContext)?
    let completion: ((DecisionFlowOutcome) -> Void)?

    init(context: any DecisionFlowContext, completion: ((DecisionFlowOutcome)->Void)? = nil) {
        self.context = context
        self.completion = completion
    }

    func start() {
        guard let context else { return }
        
        if let url = context.document?.designURL {
            self.save(to: url)
        }
        else {
            let subflow = SaveDocumentWithFileSelectionFlow(context: context)
            { outcome in self.finish(outcome) }
            context.presentSubflow(subflow)
        }
    }
    
    func save(to url: URL) {
        guard let context else { return }
        let command = SaveDesignCommand(url: url, appendExtensionIfNeeded: true)
        do {
            try context.execute(command)
            finish(.success)
        }
        catch {
            context.presentMessage(title: "Save Failed", message: error.message, style: .error)
            finish(.failure)
        }
    }
    func finish(_ outcome: DecisionFlowOutcome) {
        guard let context else { return }
        if context.finish(self) {
            completion?(outcome)
        }
    }
}

final class SaveDocumentIfNeededFlow: DecisionFlow {
    weak let context: (any DecisionFlowContext)?
    let completion: ((DecisionFlowOutcome) -> Void)?

    init(context: any DecisionFlowContext, completion:  ((DecisionFlowOutcome)->Void)? = nil) {
        self.context = context
        self.completion = completion
    }

    func start() {
        guard let context,
              let document = context.document
        else { return }
        
        guard document.hasUnsavedChanges else {
            self.finish(.success)
            return
        }

        context.presentDecision(
            title: "Unsaved Changes",
            message: "Design contains unsaved changes. Do you want to save or discard them?",
            choices: [
                DecisionFlowChoice("Cancel") {
                    self.finish(.cancelled)
                },
                DecisionFlowChoice("Save") {
                    self.saveDocument()
                },
                DecisionFlowChoice("Discard Changes", emphasis: .destructive) {
                    self.finish(.success)
                }
            ]
        )
    }
    
    func saveDocument() {
        guard let context else { return }
        
        context.presentSubflow(SaveDocumentFlow(context: context, completion: self.finish))
    }
    
    func finish(_ outcome: DecisionFlowOutcome) {
        guard let context else { return }
        if context.finish(self) {
            completion?(outcome)
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
        
        let subflow = SaveDocumentIfNeededFlow(context: context) { [weak self] completion in
            if completion == .success {
                self?.selectDocumentFile()
            }
            else {
                self?.finish(.cancelled)
            }
        }
        context.presentSubflow(subflow)
    }
    
    func selectDocumentFile() {
        guard let context else { return }
        
        context.presentFilePicker(title: "Open Document",
                                  mode: .open,
                                  filter: "*." + Document.FileExtension)
        { [weak self] selectedPath in
            guard let selectedPath else {
                self?.finish(.cancelled)
                return
            }
            
            let url = URL(fileURLWithPath: selectedPath)
            self?.open(from: url)
        }

    }
    
    func open(from url: URL) {
        guard let context else { return }
        let command = OpenDesignCommand(url: url)
        do {
            try context.execute(command)
            finish(.success)
        }
        catch {
            context.presentMessage(title: "Open Failed", message: error.message, style: .error)
            finish(.failure)
        }
    }
    
    func finish(_ outcome: DecisionFlowOutcome) {
        guard let context else { return }
        context.finish(self)
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
        
        let subflow = SaveDocumentIfNeededFlow(context: context) { [weak self] completion in
            if completion == .success, let self {
                self.open(from: self.url)
            }
            else {
                self?.finish(.cancelled)
            }
        }
        context.presentSubflow(subflow)
    }
    
    func open(from url: URL) {
        guard let context else { return }
        let command = OpenDesignCommand(url: url)
        do {
            try context.execute(command)
            finish(.success)
        }
        catch {
            context.presentMessage(title: "Open Failed", message: error.message, style: .error)
            finish(.failure)
        }
    }
    
    func finish(_ outcome: DecisionFlowOutcome) {
        guard let context else { return }
        context.finish(self)
    }
}

final class QuitApplicationFlow: DecisionFlow {
    weak let context: (any DecisionFlowContext)?

    init(context: any DecisionFlowContext) {
        self.context = context
    }

    func start() {
        guard let context else { return }

        let subflow = SaveDocumentIfNeededFlow(context: context) { [weak self] completion in
            print(">>> QUIT: SAVE COMPLETION: \(completion)")
            guard completion == .success else {
                self?.finish(.cancelled)
                return
            }
                
            do {
                try context.execute(QuitApplicationCommand())
                self?.finish(.success)
            }
            catch {
                // FIXME: Why `error` is not CommandError here but it is `any Error`?
                context.presentMessage(title: "Quit", message: error.localizedDescription, style: .error)
                self?.finish(.failure)
            }
        }
        context.presentSubflow(subflow)

        // TODO: Implement
        // 1. Sub-flow: SaveDocumentIfNeededFlow
        // 2. Flag application as "quit requested"
        
    }
    func finish(_ outcome: DecisionFlowOutcome) {
        print(">>> QUIT: FINISH")
        guard let context else { return }
        context.finish(self)
    }
}

class QuitApplicationCommand: Command {
    var name: String { "quit" }

    func run(_ context: CommandContext) throws (CommandError) {
        context.app.quitRequested = true
    }
}

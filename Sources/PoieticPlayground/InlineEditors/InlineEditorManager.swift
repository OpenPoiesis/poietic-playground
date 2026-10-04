//
//  InlineEditorManager.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 24/02/2026.
//

import CIimgui
import PoieticCore
import Diagramming

@MainActor
class InlineEditorManager {
    weak var canvas: DiagramCanvas?
    weak var document: Document?
    weak var traitEnvironment: any TraitEnvironment? = nil

    private var editors: [String:InlineEditor] = [:]
    private(set) var currentEditor: (InlineEditor)? = nil
    private(set) var currentEntity: RuntimeEntity? = nil
    
    func register(name: String, editor: InlineEditor) {
        self.editors[name] = editor
    }
    
    func bind(document: Document, canvas: DiagramCanvas, traitEnvironment: TraitEnvironment) {
        self.document = document
        self.canvas = canvas
        self.traitEnvironment = traitEnvironment
    }
    func unbind() {
        self.document = nil
        self.canvas = nil
        self.traitEnvironment = nil
    }
    
    func openEditor(_ editorName: String, for entity: RuntimeEntity) {
        guard let traitEnvironment else { return }
        close()
        
        guard let editor = editors[editorName],
              let document,
              let canvas
        else { return }
        
        let rect = editor.preferredBox(for: entity)
        editor.bind(document: document, canvas: canvas, traitEnvironment: traitEnvironment)
        
        if editor.open(for: entity) {
            currentEditor = editor
            currentEntity = entity
        }
    }

    func close() {
        guard let currentEditor else { return }
        currentEditor.close()
        self.currentEditor = nil
        self.currentEntity = nil
    }
    
    func draw() {
        guard let editor = currentEditor else { return }
        
        if editor.draw() {
            close()
        }
    }
}

@MainActor
class InlineEditor {
    weak var canvas: DiagramCanvas?
    weak var document: Document?
    weak var traitEnvironment: any TraitEnvironment? = nil

    func bind(document: Document, canvas: DiagramCanvas, traitEnvironment: TraitEnvironment) {
        self.document = document
        self.canvas = canvas
        self.traitEnvironment = traitEnvironment
    }

    func open(for entity: RuntimeEntity) -> Bool {
        // Subclasses should override this.
        return false
    }
    /// Draw the editor and return `true` when finished (should be closed).
    func draw() -> Bool { return true }
    func close() { /* nothing */ }
}

extension InlineEditor {
    /// Get an empty box at design object's position, if present.
    func preferredBox(for entity: RuntimeEntity) -> Rect2D? {
        guard let object = entity.designObject,
              let position = object.position
        else { return nil }
        return Rect2D(origin: position, size: .zero)
    }
}

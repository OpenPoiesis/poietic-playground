//
//  ApplicationFlows.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 13/09/2026.
//


final class QuitApplicationFlow: DecisionFlow {
    let context: DecisionFlowContext

    init(context: DecisionFlowContext) {
        self.context = context
    }

    func start() {
        // TODO: Once with multi-document app run this sub-flow for each document
        guard let workspace = context.workspace,
              let document = workspace.currentDocument
        else {
            context.requestQuit()
            context.finish(self, outcome: .success)
            return
        }

        let saveIfNeeded = SaveDocumentIfNeededFlow(context: context, document: document)

        context.startSubflow(saveIfNeeded) { [weak self] completion in
            guard let self else { return }
            
            switch completion {
            case .success:
                context.requestQuit()
                context.finish(self, outcome: .success)
            case .cancelled, .failure:
                context.finish(self, outcome: .cancelled)
            }
        }
    }
}

final class NewDesignFlow: DecisionFlow {
    let context: DecisionFlowContext

    init(context: DecisionFlowContext) {
        self.context = context
    }

    func start() {
        // TODO: This goes away with multi-document app
        guard let workspace = context.workspace else {
            context.finish(self, outcome: .failure)
            return
        }
        guard let document = workspace.currentDocument
        else {
            workspace.newDesign()
            context.finish(self, outcome: .success)
            return
        }

        let subflow = SaveDocumentIfNeededFlow(context: context, document: document)

        context.startSubflow(subflow) { [weak self] outcome in
            guard let self else { return }
            switch outcome {
            case .success:
                context.workspace?.newDesign()
                context.finish(self, outcome: .success)
            case .cancelled, .failure:
                context.finish(self, outcome: .cancelled)
            }
        }
    }
}


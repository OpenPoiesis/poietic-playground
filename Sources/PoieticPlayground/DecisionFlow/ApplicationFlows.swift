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
        let saveIfNeeded = SaveDocumentIfNeededFlow(context: context)

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
        let subflow = SaveDocumentIfNeededFlow(context: context)

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


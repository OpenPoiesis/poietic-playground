//
//  ApplicationFlows.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 13/09/2026.
//


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


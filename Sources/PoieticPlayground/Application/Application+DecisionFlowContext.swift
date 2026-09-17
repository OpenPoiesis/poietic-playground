//
//  Application+DecisionFlowContext.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 12/09/2026.
//

@MainActor
extension Application: ApplicationEnvironment {
    
}

extension Application {
    func flowContext() -> DecisionFlowContext {
        return DecisionFlowContext(environment: self, workspace: workspace)
    }
    
    func presentMessage(title: String, message: String, style: MessageStyle) {
        let alert = ConfirmationDialog(
            title: title,
            message: message,
            style: style,
            options: [
                DecisionOption("Dismiss")
            ]
        )
        
        queueDialog(alert)
    }
    func presentDecision(title: String, message: String, choices: [DecisionFlowChoice])
    {
        let options = choices.map { $0.option }
        let dialog = ConfirmationDialog(title: title,
                                        message: message,
                                        options: options)
        { option in
            guard option >= 0 && option < choices.count else { return }
            choices[option].action()
        }
        
        queueDialog(dialog)
                                        
    }
    
    func presentFileSelector(title: String,
                           mode: FileSelectionMode,
                           filter: String?,
                           completion: @escaping (String?) -> Void)
    {
        self.openFileSelector(title: title, mode: mode, filter: filter, callback: completion)
    }

    func startSubflow(_ flow: any DecisionFlow, completion: @escaping ((DecisionFlowOutcome)->Void)) {
        decisionManager.presentSubflow(flow, completion: completion)
    }
    func finish(_ flow: any DecisionFlow, outcome: DecisionFlowOutcome) {
        decisionManager.finish(flow, outcome: outcome)
    }

}

extension Application {
    func startFlow(_ flow: DecisionFlow) {
        self.decisionManager.start(flow)
    }
}

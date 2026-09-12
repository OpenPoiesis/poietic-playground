//
//  Application+DecisionFlowContext.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 12/09/2026.
//

extension Application: DecisionFlowContext {
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
        self.openFileSelector(title: title,
                            mode: mode,
                            filter: filter,
                            callback: completion)
    }

    // Execute command immediately
    func execute(_ command: any Command) throws (CommandError) {
        guard let document else {
            self.log("Trying to execute a command \(type(of: command)) without a document")
            return
        }
        let context = CommandContext(app: self, document: document)
        try command.run(context)
    }
    func queue(_ command: any Command) {
        self.document?.queueCommand(command)
    }
    func presentSubflow(_ flow: any DecisionFlow, completion: @escaping ((DecisionFlowOutcome)->Void)) {
        decisionManager.presentSubflow(flow, completion: completion)
    }
    func finish(_ flow: any DecisionFlow, outcome: DecisionFlowOutcome) {
        decisionManager.finish(flow, outcome: outcome)
    }

}

extension Application {
    func run(_ flow: DecisionFlow) {
        self.decisionManager.start(flow)
    }
}

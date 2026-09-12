//
//  DecisionFlow.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 10/09/2026.
//

@MainActor
protocol DecisionFlow: AnyObject {
    var name: String { get }
    func start()
}

extension DecisionFlow {
    var name: String {
        return String(describing: type(of: self))
    }
}

public enum DecisionFlowOutcome {
    /// The flow succeeded
    case success
    /// The flow failed, the caller might cancel, fail, consider resuming or taking alternative
    /// route.
    case failure
    /// The flow was cancelled, the caller is recommended to cancel as well.
    case cancelled

}

struct DecisionOption {
    enum Emphasis {
        case neutral
        case primary
        case destructive
    }

    let label: String
    let emphasis: Emphasis
    
    init(_ label: String, emphasis: Emphasis = .neutral) {
        self.label = label
        self.emphasis = emphasis
    }
}

struct DecisionFlowChoice {
    let option: DecisionOption
    let action: () -> Void
    init(_ label: String, emphasis: DecisionOption.Emphasis = .neutral, action: @escaping ()-> Void) {
        self.option = DecisionOption(label, emphasis: emphasis)
        self.action = action
    }
}

enum FilePickerMode {
// TODO: The cases map the ImGui file picker for now, we would prefer: {open|save} x {file|dir|any}
    case open
    case save
    case openDirectory
}

@MainActor
protocol DecisionFlowContext: AnyObject {
    // TODO: Do not provide whole document
    var document: Document? { get }
    
    func presentMessage(title: String, message: String, style: MessageStyle)
    func presentDecision(title: String,
                         message: String,
                         choices: [DecisionFlowChoice])
    func presentFilePicker(title: String,
                           mode: FilePickerMode,
                           filter: String?,
                           completion: @escaping (String?) -> Void)

    // Execute command immediately
    func execute(_ command: any Command) throws (CommandError)
    func queue(_ command: any Command)
    func presentSubFlow(_ flow: any DecisionFlow)
    @discardableResult
    func finish(_ flow: any DecisionFlow) -> Bool
}

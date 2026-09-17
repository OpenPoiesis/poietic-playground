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

/// Final result of a flow.
///
/// Use for flows whose parents-presenters only need to know whether the flow succeeded,
/// failed or was cancelled. Flows that need to communicate more information define their
/// custom outcome enum or structure.
///
enum DecisionFlowOutcome {
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

/// A choice in a decision dialog that couples label, emphasis style and action.
/// Represented by a button in a decision dialog.
///
/// ## Example
///
/// ```swift
/// let context: any DecisionFlowContext // Assume this exists, typically in a decision flow
///
/// context.presentDecision(
///     title: "Unsaved Changes",
///     message: "Design contains unsaved changes. Do you want to save or discard them?",
///     choices: [
///         DecisionFlowChoice("Cancel") {
///             // Cancel the flow
///         },
///         DecisionFlowChoice("Save") {
///             // Save the document
///         },
///         DecisionFlowChoice("Discard Changes", emphasis: .destructive) {
///             // Communicate to the parent flow that we succeeded
///         }
///     ]
/// )
/// ```
///
struct DecisionFlowChoice {
    /// Description of the choice: label and emphasis style.
    let option: DecisionOption
    /// Action to be called when the choice is chosen by the user.
    let action: () -> Void
    
    init(_ label: String, emphasis: DecisionOption.Emphasis = .neutral, action: @escaping ()-> Void) {
        self.option = DecisionOption(label, emphasis: emphasis)
        self.action = action
    }
}

@MainActor
struct DecisionFlowContext {
    private weak let environment: ApplicationEnvironment?
    weak let workspace: Workspace?
   
    var document: Document? { workspace?.currentDocument }
    
    init(environment: ApplicationEnvironment, workspace: Workspace?) {
        self.environment = environment
        self.workspace = workspace
    }
    
    // TODO: Do not provide whole document
    func presentMessage(title: String, message: String, style: MessageStyle) {
        environment?.presentMessage(title: title, message: message, style: style)
    }
    func presentDecision(title: String,
                         message: String,
                         choices: [DecisionFlowChoice]) {
        environment?.presentDecision(title: title, message: message, choices: choices)
    }
    func presentFileSelector(title: String,
                             mode: FileSelectionMode,
                             filter: String?,
                             completion: @escaping (String?) -> Void)
    {
        environment?.presentFileSelector(title: title, mode: mode, filter: filter, completion: completion)
    }

    /// Present another flow as a sub-flow.
    ///
    /// - Important: The `completion` must call ``DecisionFlowContext/finish(_:outcome:)``.
    ///
    func startSubflow(_ flow: any DecisionFlow, completion: @escaping ((DecisionFlowOutcome)->Void)) {
        environment?.startSubflow(flow, completion: completion)
    }

    // Execute command immediately
    func execute(_ command: any Command, document: Document) throws (CommandError) {
        guard let workspace else {
            throw CommandError("Flow without workspace", kind: .internal)
        }
        try workspace.execute(command, document: document)

    }
    // TODO: Do we still need this here? Maybe for workspace ownership validation?
    func enqueue(_ command: any Command, document: Document) {
        document.enqueue(command)
    }
    func finish(_ flow: any DecisionFlow, outcome: DecisionFlowOutcome) {
        environment?.finish(flow, outcome: outcome)
    }

    // Other capabilities
    func requestQuit() {
        environment?.requestQuit()
    }
}

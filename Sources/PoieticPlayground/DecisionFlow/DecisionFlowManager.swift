//
//  DecisionFlowManager.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 11/09/2026.
//

@MainActor
class DecisionFlowManager {
    struct Item {
        let flow: any DecisionFlow
        let completion: ((DecisionFlowOutcome)->Void)?
    }
    
    
    var pending: [Item] = []
    var stack: [Item] = []
    var startRequested: Bool = false

    var isActive: Bool { !stack.isEmpty }
    
    
    func discardAll() {
        self.pending.removeAll()
        self.stack.removeAll()
        self.startRequested = false
    }
    
    func start(_ flow: any DecisionFlow, completion: ((DecisionFlowOutcome)->Void)? = nil) {
        print(">>> FLOW QUEUED: \(type(of: flow))")
        print("--- Stack: \(stack.count) Pending: \(pending.count)")
        let item = Item(flow: flow, completion: completion)
        self.pending.append(item)
    }
    
    func presentSubflow(_ flow: any DecisionFlow, completion: @escaping ((DecisionFlowOutcome)->Void)) {
        let item = Item(flow: flow, completion: completion)
        self.stack.append(item)
        startRequested = true
    }

    /// Mark flow as finished and call completion, if present,  with given outcome.
    ///
    /// - Precondition: Only current flow must call this method.
    ///
    func finish(_ flow: any DecisionFlow, outcome: DecisionFlowOutcome) {
        guard stack.last?.flow === flow else {
            precondition(!stack.contains {$0.flow === flow }, "Flow finished out of order")
            return
        }
        
        let item = stack.removeLast()
        item.completion?(outcome)
    }

    func update() {
        if stack.isEmpty, !pending.isEmpty {
            stack.append(pending.removeFirst())
            startRequested = true
        }
        while let top = stack.last, startRequested {
            startRequested = false
            print("Starting \(type(of: top.flow))")
            top.flow.start()
            // `start()` may:
            //  - present a dialog: loop ends (interaction blocked)
            //  - queue a sub-flow: topNeedsStart set again → loop continues
            //  - finish          : pops itself; completion resumes the parent
        }
    }
}

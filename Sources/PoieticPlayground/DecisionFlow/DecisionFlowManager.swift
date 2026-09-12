//
//  DecisionFlowManager.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 11/09/2026.
//

@MainActor
class DecisionFlowManager {
    var pending: [any DecisionFlow] = []
    var stack: [any DecisionFlow] = []
    var startRequested: Bool = false

    var isActive: Bool { !stack.isEmpty }
    
    func start(_ flow: any DecisionFlow) {
        print(">>> FLOW QUEUED: \(type(of: flow))")
        print("--- Stack: \(stack.count) Pending: \(pending.count)")
        self.pending.append(flow)
    }
    
    func presentSubflow(_ flow: any DecisionFlow) {
        self.stack.append(flow)
        startRequested = true
    }

    func finish(_ flow: any DecisionFlow) -> Bool {
        print("<-- FLOW FINISHED: \(type(of: flow))")
        print("--- Stack: \(stack.count-1) Pending: \(pending.count)")
        assert(stack.last === flow, "Finished flow is different from active flow")
        guard stack.last === flow else { return false }
        stack.removeLast()
        return true
    }

    func update() {
        if stack.isEmpty, !pending.isEmpty {
            stack.append(pending.removeFirst())
            startRequested = true
        }
        while let top = stack.last, startRequested {
            startRequested = false
            print("Starting \(type(of: top))")
            top.start()
            // `start()` may:
            //  - present a dialog: loop ends (interaction blocked)
            //  - queue a sub-flow: topNeedsStart set again → loop continues
            //  - finish          : pops itself; completion resumes the parent
        }
    }
}

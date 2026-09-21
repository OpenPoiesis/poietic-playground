//
//  ToolInteraction.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 21/09/2026.
//

enum EventDisposition {
    /// Tool interaction is not concerned about the event, try fallback.
    case ignored
    /// The tool interaction has processed the event and has finished interacting.
    case handled
    /// Interaction has processed the event and will handle all future events until finished or
    /// cancelled.
    case engaged
}


/// Tool interactions handle tool events and hold interaction state.
///
/// Interactions are created by ``CanvasTool/makeInteraction(context:)``.
///
/// - SeeAlso: ``CanvasTool``
/// 
@MainActor
protocol ToolInteraction {
    func begin()
    func end()
    func handleEvent(_ event: ToolEvent) -> EventDisposition
}

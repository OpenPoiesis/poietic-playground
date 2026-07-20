//
//  Schedules.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 05/02/2026.
//

import PoieticCore
import PoieticFlows
import Diagramming

// Inherited schedules:
// - FrameChangeSchedule
// - SimulationSchedule

/// Result player step update.
//enum ReplayStepSchedule: ScheduleLabel { }

// TODO: Maybe a better, shorter name?
/// Systems run on every document update
///
enum DocumentVisualsUpdateSchedule: ScheduleLabel { }

/// Systems run during interactive editing such as selection movement or handle dragging.
///
enum InteractivePreviewSchedule: ScheduleLabel { }

// Action-specific schedules
enum ParameterResolutionSchedule: ScheduleLabel { }

extension Document {
    static func setupSchedules(_ world: World) {
        world.addSchedule(Schedule(
            label: FrameChangeSchedule.self,
            systems:
                PoieticFlows.SimulationPlanningSystems
                + [
                    NewChartResolutionSystem.self,
                    // From Diagramming
                    ErrorIndicatorSystem.self,
                    DiagramObjectsFromTraitsSystem.self,
                    // FIXME: Add geometry system
                ]
        ))
        world.addSchedule(Schedule(
            label: DocumentVisualsUpdateSchedule.self,
            systems: [
                    SceneCompositionSystem.self,
                ]
        ))

        world.addSchedule(Schedule(
            label: InteractivePreviewSchedule.self,
            systems: [
                // TODO: Remove error indicator system once we have relative placement
                ErrorIndicatorSystem.self,
                // From Diagramming
//                ConnectorGeometrySystem.self,
            ]
        ))

        world.addSchedule(Schedule(
            label: SimulationSchedule.self,
            systems: [
                StockFlowSimulationSystem.self,
                TimeSeriseProcessingSystem.self,
            ]
        ))

        // TODO: Remove or reconsider (I think it was used for auto-connect)
//        world.addSchedule(Schedule(
//            label: ParameterResolutionSchedule.self,
//            systems: [
//                ComputationOrderSystem.self,
//                NameResolutionSystem.self,
//                ExpressionParserSystem.self,
//                ParameterResolutionSystem.self,
//                ParameterConnectionProposalSystem.self,
//            ]
//        ))
    }
    
    func onSimulationPlayerStep(_ document: Document) {
        // TODO: This is weird, as we should be receiving this event only triggered by us.
        
    }

}

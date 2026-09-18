//
//  Document+World.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 05/03/2026.
//

import PoieticCore
import Diagramming
import PoieticFlows

/// Systems run on every document update
///
enum DocumentUpdateSchedule: ScheduleLabel { }
enum DocumentCleanupSchedule: ScheduleLabel { }

/// Schedule run on simulation player set.
///
/// - SeeAlso: ``ResultPlayer``
///
enum PlayerStepSchedule: ScheduleLabel { }

/// Systems run during interactive editing such as selection movement or handle dragging.
///
enum InteractivePreviewSchedule: ScheduleLabel { }

// Action-specific schedules
enum ParameterResolutionSchedule: ScheduleLabel { }

extension Document {
    static func setupSchedules(_ world: World) {
        let schedules: [Schedule] = [
            Schedule(
                label: DocumentUpdateSchedule.self,
                systems: [
                        SceneCompositionSystem.self,
                        SceneInteractionSystem.self,
                    ],
                order: [
                    (SceneCompositionSystem.self, before: SceneInteractionSystem.self),
                ]
            ),
            Schedule(
                label: DocumentCleanupSchedule.self,
                systems: [
                        DocumentCleanupSystem.self,
                ]
            ),
            Schedule(
                label: PlaneChangeSchedule.self,
                systems:
                    PoieticFlows.SimulationPlanningSystems
                    + [
                        ChartResolutionSystem.self,
                        TraitsToDiagramObjectsSystem.self,
                        VisualMetadataSystem.self,
                    ]
            ),
            Schedule(
                label: InteractivePreviewSchedule.self,
                systems: [ ]
            ),
            Schedule(
                label: SimulationSchedule.self,
                systems: [
                    StockFlowSimulationSystem.self,
                    TimeSeriesProcessingSystem.self,
                    SimulationSamplingSystem.self,
                ],
                order: [
                    (TimeSeriesProcessingSystem.self, before: SimulationSamplingSystem.self),
                ]
            ),
            Schedule(
                label: PlayerStepSchedule.self,
                systems: [
                    SimulationSamplingSystem.self,
                ]
            )
        ]
        for schedule in schedules {
            world.addSchedule(schedule)
        }

    }

    /// Set world singletons when the world changes.
    func setupWorld(notation: Notation? = nil) {
        Self.setupSchedules(world)
        
        if let notation {
            world.setSingleton(notation)
        }
        else {
            world.setSingleton(Notation.DefaultNotation)
        }
    }
    
    /// Update the world by running system schedules.
    ///
    /// When design plane changes:
    ///
    /// 1. Run plane change schedule
    /// 2. Update selection overview – ``SelectionOverview`` stats in ``selectionOverview``.
    /// 3. Run simulation schedule
    /// 4. If required, run interactive preview schedule
    ///
    func update(_ timeDelta: Double) throws (InternalSystemError) {
        if needsWorldPlaneUpdate || design.currentPlane !== world.plane {
            try changeWorldPlaneAndSimulate()
        }
        
        try world.run(schedule: DocumentUpdateSchedule.self)
        
        if requiresInteractivePreviewUpdate {
            try world.run(schedule: InteractivePreviewSchedule.self)
            resetInteractivePreviewUpdate()
            trigger(.previewChanged)
        }
    }

    func changeWorldPlaneAndSimulate() throws (InternalSystemError) {
        if let plane = design.currentPlane {
            world.setPlane(plane)
        }
        else {
            world.removePlane()
        }
        try world.run(schedule: PlaneChangeSchedule.self)
        createOrUpdateMainDiagram()
        updateSelectionOverview()
        trigger(.designPlaneChanged)
        trigger(.selectionChanged)
        
        try world.run(schedule: SimulationSchedule.self)
        
        if world.hasSingleton(SimulationResult.self) {
            trigger(.simulationFinished)
        }
        else {
            trigger(.simulationFailed)
        }
        
        needsWorldPlaneUpdate = false
    }
    func createOrUpdateMainDiagram() {
        let diagram = DiagramSceneComposer.createDiagramFromAll(world: world, diagram: mainDiagram)
        self.mainDiagram = diagram
    }
}

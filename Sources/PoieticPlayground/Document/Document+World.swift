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
                    (SimulationSamplingSystem.self, before: SceneCompositionSystem.self),
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
                label: FrameChangeSchedule.self,
                systems:
                    PoieticFlows.SimulationPlanningSystems
                    + [
                        NewChartResolutionSystem.self,
                        TraitsToDiagramObjectsSystem.self,
                    ]
            ),
            Schedule(
                label: InteractivePreviewSchedule.self,
                systems: [
                    // FIXME: No longer needed?
                ]
            ),
            Schedule(
                label: SimulationSchedule.self,
                systems: [
                    StockFlowSimulationSystem.self,
                    TimeSeriesProcessingSystem.self,
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
    /// When design frame changes:
    ///
    /// 1. Run frame change schedule
    /// 2. Update selection overview – ``SelectionOverview`` stats in ``selectionOverview``.
    /// 3. Run simulation schedule
    /// 4. If required, run interactive preview schedule
    ///
    func update(_ timeDelta: Double) {
        if needsWorldFrameUpdate || design.currentFrame !== world.frame {
            changeWorldFrame()
        }
        
        self.run(schedule: DocumentUpdateSchedule.self)
        
        if requiresInteractivePreviewUpdate {
            self.run(schedule: InteractivePreviewSchedule.self)
            resetInteractivePreviewUpdate()
            trigger(.previewChanged)
        }
    }
    // TODO: Maybe we need a better name?
    func changeWorldFrame() {
        if let frame = design.currentFrame {
            world.setFrame(frame)
        }
        else {
            world.removeFrame()
        }
        self.run(schedule: FrameChangeSchedule.self)
        createOrUpdateMainDiagram()
        updateSelectionOverview()
        trigger(.designFrameChanged)
        trigger(.selectionChanged)
        
        if self.run(schedule: SimulationSchedule.self) {
            trigger(.simulationFinished)
        }
        else {
            trigger(.simulationFailed)
        }
        needsWorldFrameUpdate = false
    }
    func createOrUpdateMainDiagram() {
        if let mainDiagram {
            if world.contains(mainDiagram) {
                mainDiagram.despawn()
            }
            self.mainDiagram = nil
        }
        let diagram = DiagramSceneComposer.createDiagramFromAll(world: world)
        self.mainDiagram = diagram
    }
    
    /// Convenience runner of a schedule that handles errors and displays an error panel through
    /// the application.
    ///
    /// World runs a given schedule. If an error occurs then it is displayed to the user through
    /// the application.
    ///
    /// - Returns: `true` on successful run, `false` on error.
    ///
    @discardableResult
    func run(schedule: ScheduleLabel.Type) -> Bool {
        let label = String(describing: schedule)
//        log("Running schedule: \(label)")
        do {
//            print("⚙️ Running schedule \(schedule)")
            try world.run(schedule: schedule)
        }
        catch {
            self.queueAlert(title: "Internal System Error", message: String(describing: error))
            self.logError("Internal system error:" + String(describing: error))
            return false
        }
        return true
    }
}

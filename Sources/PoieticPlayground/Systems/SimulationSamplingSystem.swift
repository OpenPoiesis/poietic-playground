//
//  SimulationSamplingSystem.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 21/07/2026.
//

import PoieticCore
import PoieticFlows


/// System that assigns current numeric value to the simulation objects.
///
/// - **Dependency:** no dependency
/// - **Input:**
///     - Singleton ``SimulationResult``
///     - Singleton ``SimulationReplayTime`` for current simulation step
///     - Singleton ``SimulationPlan`` for simulation object list
/// - **Output:** Assign ``NumericSimulationSample`` for entities which have current simulation
///     value, remove from entities where the value is missing in the current state.
/// - **Forgiveness:** Does nothing if any of the singletons are not present.
///
struct SimulationSamplingSystem: System {
    // TODO: This is using old way of storing simulation data - in their respective structures, instead of components.
    nonisolated(unsafe) public static let dependencies: [SystemDependency] = [
    ]
    
    init(_ world: World) {    }
    
    func update(_ world: World) throws(InternalSystemError) {
        guard let result: SimulationResult = world.singleton(),
              let time: SimulationReplayTime = world.singleton(),
              let plan: SimulationPlan = world.singleton(),
              let state = result[time.step]
        else { return }
        
        for simObject in plan.simulationObjects {
            guard let entity = world.entity(simObject.objectID) else { continue }
            let value: Variant = state[simObject.variableIndex]
            if let doubleValue = try? value.doubleValue() {
                entity.setComponent(NumericValueSample(value: doubleValue))
            }
            else {
                entity.removeComponent(NumericValueSample.self)
            }
        }
    }
}

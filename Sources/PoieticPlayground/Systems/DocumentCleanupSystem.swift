//
//  DocumentCleanupSystem.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 30/07/2026.
//

import PoieticCore
import Diagramming

/// System that cleans-up temporary components that are valid only during document update cycle.
///
/// - **Dependency:** no dependency
/// - **Input:** Design object entities
/// - **Change:**
///     - Removes all of the following components:
///         - ``PreviewPositionComponent``
///         - ``PreviewMidpoints``
///         - ``Diagram/DirtyContent``
///         - ``InteractionDirty``
///         - ``LayoutDirty``
/// - **Output:** No output.
/// - **Forgiveness:** Nothing to be forgiven.
///
struct DocumentCleanupSystem: System {
    nonisolated(unsafe) public static let dependencies: [SystemDependency] = [ ]
    
    init(_ world: PoieticCore.World) { }
    
    func update(_ world: PoieticCore.World) throws(PoieticCore.InternalSystemError) {
        world.removeComponentForAll(DirtyContent.self)
        world.removeComponentForAll(ViewportDirty.self)
//        world.removeComponentForAll(InteractionDirty.self)
        world.removeComponentForAll(ObjectTouched.self)
    }
}

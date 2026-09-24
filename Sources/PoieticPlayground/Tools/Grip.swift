//
//  Grip.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 23/09/2026.
//

import PoieticCore
import Diagramming

enum GripKey {
    /// Grip representing a connector mid-point.
    ///
    /// - SeeAlso: ``MidpointGripInteraction``.
    ///
    case connectorMidpoint(Int)
    // TODO: Add the following types and functionality
    // case connect(ObjectType) – grip from which a new connector can be dragged
}

/// Visual grip (handle) to interactively manipulate canvas objects.
///
/// Related components and relationships attached to the same entity:
/// - `GripOf`: Object that the grip manipulates. When the target of the relationship is
///   despawned, the grip is despawned as well.
///
/// Grip is a diagram scene node with a position.
///
/// - Important: Grip must be a direct child of a scene.
///
struct Grip: Component {
    static let DefaultSize = 8.0
    
    let key: GripKey
    
    /// Current position of the grip in world coordinates.
    ///
    /// Use this position for drawing the grip and for creating a transaction when dragging
    /// operation is concluded.
    ///
    /// - Note: Grip position in the scene is determined by the ``PositionComponent`` on the
    /// grip entity.
    ///
    var worldPosition: Vector2D
    
    init(position: Vector2D, key: GripKey) {
        self.worldPosition = position
        self.key = key
    }
}

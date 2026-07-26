//
//  CanvasComponents.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 16/02/2026.
//

import PoieticCore
import Diagramming

struct ScreenPosition: Component {
    let position: Vector2D
}
struct ScreenSize: Component {
    let size: Vector2D
}

struct BlockIntent: Component {
    let type: ObjectType
    var position: Vector2D
    let pictogram: Pictogram
}

// TODO: Relationship
/// Component for a connector that is intended to be created within an interactive operation.
///
/// Created by ``ConnectTool``.
///
/// Entity structure with connector intent:
/// - ``DiagramSceneNode``: primary entity type tag
/// - ``ConnectorCanvasNode``: tag, picked up by the renderer
/// - ``ConnectorGlyph``
/// - ``CanvasNodeStyle/preview``: denotes that this is an intent
///
/// Computed components:
///
/// - ``ConnectorGeometry``: computed by the composer, used by the renderer
/// - ``ConnectorWire``: computed by composer
/// - ``ConnectorStroke``: computed by composer
///
/// Relationships:
/// - ``ChildOf``: scene
/// - ``ConnectorCanvasNode/Origin``: origin block entity for computing geometry
/// - ``ConnectorCanvasNode/Target``: target block entity, if connected
///
/// - Note: ``ConnectorIntent`` should not have ``RepresentationOf`` relationship, as it does not yet
/// represent anything.
///
struct ConnectorIntent: Component {
    /// Object type of the connector to be created.
    let type: ObjectType
    let targetAllowed: Bool
}

/// Visual handle to interactively manipulate canvas objects.
///
/// Related components and relationships attached to the same entity:
/// - ``Handles``: Object that the handle manipulates. When the target of the relationship is
///   despawned, the handle is despawned as well.
///
struct CanvasHandle: Component {
    static let DefaultSize = 8.0
    
    enum Kind {
        /// Handle representing a connector mid-point.
        ///
        /// - SeeAlso: ``SelectionTool/dragMidpointHandle(_:index:currentPosition:currentDelta:)``,
        /// ``SelectionTool/finalizeHandleMove(_:finalPosition:totalDelta:)``
        /// 
        case midpoint(Int)
        // TODO: Add the following types and functionality
        // case connect(ObjectType) – handle from which a new connector can be dragged
    }
    let kind: Kind
    /// Current position of the handle in world coordinates.
    ///
    /// Use this position for drawing the handle and for creating a transaction when dragging
    /// operation is concluded.
    var position: Vector2D
    
    init(position: Vector2D, kind: Kind) {
        self.position = position
        self.kind = kind
    }
}

//
//  CanvasComponents.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 16/02/2026.
//

import PoieticCore
import Diagramming

struct BlockIntent: Component {
    let type: ObjectType
}

// TODO: Relationship
/// Component for a connector that is intended to be created within an interactive operation.
///
/// Created by ``ConnectTool``.
///
/// Entity structure with connector intent:
/// - ``DiagramSceneNode``: primary entity type tag
/// - ``ConnectorSceneNode``: tag, picked up by the renderer
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
/// - ``ConnectorSceneNode/Origin``: origin canvas block entity for computing geometry
/// - ``ConnectorSceneNode/Target``: target canvas block entity or just an entity with position component
///
/// - Note: ``ConnectorIntent`` should not have ``RepresentationOf`` relationship, as it does not yet
/// represent anything.
///
struct ConnectorIntent: Component {
    /// Object type of the connector to be created.
    let type: ObjectType
//    let targetAllowed: Bool
}


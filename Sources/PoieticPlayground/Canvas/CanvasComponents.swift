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
/// - ``PresentationNode``: primary entity type tag
/// - ``ConnectorNode``: tag, picked up by the renderer
/// - ``ConnectorGlyph``
/// - ``NodeStyle/preview``: denotes that this is an intent
///
/// Computed components:
///
/// - ``ConnectorGeometry``: computed by the builder, used by the renderer
/// - ``ConnectorWire``: computed by builder
/// - ``ConnectorStroke``: computed by builder
///
/// Relationships:
/// - ``ChildOf``: presentation
/// - ``ConnectorNode/Origin``: origin canvas block entity for computing geometry
/// - ``ConnectorNode/Target``: target canvas block entity or just an entity with position component
///
/// - Note: ``ConnectorIntent`` should not have ``RepresentationOf`` relationship, as it does not yet
/// represent anything.
///
struct ConnectorIntent: Component {
    /// Object type of the connector to be created.
    let type: ObjectType
//    let targetAllowed: Bool
}


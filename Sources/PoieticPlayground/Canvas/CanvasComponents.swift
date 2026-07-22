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
struct ConnectorIntent: Component {
    let type: ObjectType
    let originID: RuntimeID
    let glyph: ConnectorGlyph
    let targetID: RuntimeID?
    let targetAllowed: Bool
}

enum TargetHighlight: Component {
    case none
    case accepting
    case notAllowed
}

/// Visual handle to interactively manipulate canvas objects.
///
/// Related components and relationships attached to the same entity:
/// - ``Handles``: Object that the handle manipulates. When the target of the relationship is
///   despawned, the handle is despawned as well.
///
struct CanvasHandle: Component {
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

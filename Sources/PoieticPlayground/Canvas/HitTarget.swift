//
//  HitTarget.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 06/02/2026.
//

import PoieticCore

/// Hit targets:
/// - object directly
/// - primary/secondary label of object
/// - error indicator of object
/// - handle of object
///     - geometry
///     - action

struct CanvasHitTarget {
    /// The scene node entity that was hit.
    let sceneNode: RuntimeID
    
    enum Kind {
        enum ObjectPart {
            /// Direct object body hit. For blocks, the pictogram's collision shape is used. For
            /// connectors a practical distance from the connector wire (center curve) is used.
            case body
            case primaryLabel
            case secondaryLabel
            case issueIndicator
        }
        
        /// A design object or its label/indicator was hit. First associated value is represented
        /// object entity ID.
        case object(RuntimeID, ObjectPart)
        /// A handle was hit. Associated value is handle entity ID.
        case handle(RuntimeID)
    }
    let kind: Kind
}

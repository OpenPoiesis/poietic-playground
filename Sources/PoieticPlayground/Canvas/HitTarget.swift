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

struct CanvasObjectHit {
    enum ObjectPart {
        /// Direct object body hit. For blocks, the pictogram's collision shape is used. For
        /// connectors a practical distance from the connector wire (center curve) is used.
        case body
        case primaryLabel
        case secondaryLabel
        case issueIndicator
    }

    let sceneNode: RuntimeID
    /// Design entity that was hit, either directly or its part.
    ///
    /// - Note: If a label or an indicator was hit, the `object` is the design object entity that
    ///         the label or the indicator belongs to.
    let designObject: RuntimeID
    let part: ObjectPart
}

struct CanvasGripHit {
    let runtimeID: RuntimeID
    let grip: Grip
}

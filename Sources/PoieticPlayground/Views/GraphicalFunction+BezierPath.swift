//
//  GraphicalFunction+BezierPath.swift
//  PoieticPlayground
//
//  Converts a GraphicalFunction into a BezierPath for rendering.

import PoieticCore
import PoieticFlows
import Diagramming

extension GraphicalFunction {

    /// Returns a BezierPath representing the curve defined by given points and method.
    ///
    /// - Parameters:
    ///     - sortedPoints: Points sorted by x-coordinate.
    ///     - method: Interpolation method.
    ///
    /// The path is built according to the function's interpolation method:
    /// - `.step`: horizontal segments from each point to the next x, then vertical step.
    /// - `.linear`: straight line segments between consecutive points.
    /// - `.cubic`: Catmull-Rom spline segments converted to cubic Bezier curves.
    /// - `.nearestStep`: same as `.step` (nearest is visualised as a step function).
    ///
    /// Returns an empty path if there are fewer than 2 points.
    ///
    /// - Note: If the input points are not sorted, the result is undefined, very likely scrambled.
    ///
    static func bezierPath(sortedPoints: [Vector2D], method: InterpolationMethod) -> BezierPath {
        guard sortedPoints.count >= 2 else { return BezierPath() }

        switch method {
        case .step, .nearestStep:
            return GraphicalFunction.stepPath(sortedPoints)
        case .linear:
            return GraphicalFunction.linearPath(sortedPoints)
        case .cubic:
            return GraphicalFunction.cubicPath(sortedPoints)
        }
    }

    /// Returns a BezierPath representing the curve defined by this function.
    ///
    /// The path is built according to the function's interpolation method:
    /// - `.step`: horizontal segments from each point to the next x, then vertical step.
    /// - `.linear`: straight line segments between consecutive points.
    /// - `.cubic`: Catmull-Rom spline segments converted to cubic Bezier curves.
    /// - `.nearestStep`: same as `.step` (nearest is visualised as a step function).
    ///
    /// Returns an empty path if there are fewer than 2 points.
    ///
    /// - Note: If the input points are not sorted, the result is undefined, very likely scrambled.
    ///
    func bezierPath() -> BezierPath {
        return GraphicalFunction.bezierPath(sortedPoints: points, method: method)
    }
    // MARK: - Step path

    private static func stepPath(_ sorted: [Point]) -> BezierPath {
        var path = BezierPath()
        path.move(to: sorted[0])
        for i in 0..<(sorted.count - 1) {
            let next = sorted[i + 1]
            let corner = Point(x: next.x, y: sorted[i].y)
            path.addLine(to: corner)
            path.addLine(to: next)
        }
        return path
    }

    // MARK: - Linear path

    private static func linearPath(_ sorted: [Point]) -> BezierPath {
        var path = BezierPath()
        path.move(to: sorted[0])
        for i in 1..<sorted.count {
            path.addLine(to: sorted[i])
        }
        return path
    }

    // MARK: - Cubic (Catmull-Rom → Bézier)

    /// Convert a Catmull-Rom spline segment to a cubic Bézier curve.
    ///
    /// For segment between `p1` and `p2` with neighbours `p0` and `p3`:
    ///   cp1 = p1 + (p2 - p0) / 6
    ///   cp2 = p2 - (p3 - p1) / 6
    private static func cubicPath(_ sorted: [Point]) -> BezierPath {
//        return BezierPath(curveThrough: sorted)
        var path = BezierPath()
        path.move(to: sorted[0])

        for i in 0..<(sorted.count - 1) {
            let p0 = sorted[max(0, i - 1)]
            let p1 = sorted[i]
            let p2 = sorted[i + 1]
            let p3 = sorted[min(sorted.count - 1, i + 2)]

            let cp1 = p1 + (p2 - p0) / 6.0
            let cp2 = p2 - (p3 - p1) / 6.0

            path.addCurve(to: p2, control1: cp1, control2: cp2)
        }
        return path
    }
}

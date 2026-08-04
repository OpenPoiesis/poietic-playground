//
//  DiagramCanvas+drawing.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 05/02/2026.
//

// TODO: [IMPORTANT] This whole file contains early prototype of all canvas drawing and needs to be split.

import CIimgui
import Ccairo
import PoieticCore
import PoieticFlows
import Diagramming
import Foundation

enum DetailLevel {
    case overview    // Visible at very low zoom (0.1x - 0.5x)
    case standard    // Visible at normal zoom (0.5x - 2.0x)
    case detailed    // Visible at high zoom (2.0x - 10.0x)
    case debug       // Only at very high zoom (10.0x+)
    
    var range: ClosedRange<Double> {
        switch self {
        case .overview: 0.1...0.5
        case .standard: 0.5...2.0
        case .detailed: 2.0...10.0
        case .debug: 10.0...100.0
        }
    }
    
    var minZoom: Float {
        switch self {
        case .overview: return 0.1
        case .standard: return 0.5
        case .detailed: return 2.0
        case .debug: return 10.0
        }
    }
    
    var maxZoom: Float {
        switch self {
        case .overview: return 0.5
        case .standard: return 2.0
        case .detailed: return 10.0
        case .debug: return 100.0
        }
    }
}

//
//  ModellingCommands.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 20/03/2026.
//

import PoieticCore
import PoieticFlows
import Foundation
import CIimgui

struct CreateChartCommand: Command {
    var name: String { "create_chart" }

    let ids: [ObjectID]
    let chartName: String?
    
    /// A chart command with series from numeric values of given objects.
    init(name: String? = nil, series: [ObjectID]) {
        self.ids = series
        self.chartName = name
    }
    
    func run(_ context: CommandContext) throws (CommandError) {
        let document = context.document
        let trans = document.createOrReuseTransaction()
        let chart = trans.createNode(StockFlowDomain.Types.Chart)
        
        if let chartName {
            chart["name"] = Variant(chartName)
        }

        for objectID in ids {
            guard let target = trans[objectID],
                  target.type.hasTrait(StockFlowDomain.Traits.ComputedValue)
            else { continue }
            trans.createEdge(StockFlowDomain.Types.ChartSeries,
                             origin: chart.objectID,
                             target: objectID)
        }
    }
}


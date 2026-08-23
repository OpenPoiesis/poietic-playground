//
//  ChartView.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 20/03/2026.
//

import CIimgui
import PoieticCore
import PoieticFlows

// FIXME: Use ImPlot (https://github.com/epezent/implot)

struct _TimeSeriesWrapper {
    let series: RegularTimeSeries
}

func chartValueGetter(data: UnsafeMutableRawPointer?, index: Int32) -> Float {
    guard let data else { return 0 }
    let series = data.assumingMemoryBound(to: _TimeSeriesWrapper.self).pointee.series
    return Float(series.data[Int(index)])
}


@MainActor
class ChartView {
    var chartEntity: RuntimeEntity?
    var chartSeries: [ChartSeries] {
        guard let chartEntity else { return [] }

        var series: [ChartSeries] = []
        for child in chartEntity.children {
            guard let seriesComponent: ChartSeries = child.component()
            else { continue }

            series.append(seriesComponent)
        }
        return series
    }
    
    var world: World? { chartEntity?.world }
    var plotSize: ImVec2

    init(chart: RuntimeEntity? = nil) {
        chartEntity = chart
        plotSize = ImVec2(100.0, 80.0)
    }
    
    func draw() {
        guard let chartEntity else { return }
        // 1. Get series
        let cursor = ImGui.GetCursorPos()
        for child in chartEntity.children {
            ImGui.SetCursorPos(cursor)
            drawSeries(chart: chartEntity, seriesEntity: child)
        }
    }

    func drawSeries(chart: RuntimeEntity, seriesEntity: RuntimeEntity) {
        guard let chartSeries: ChartSeries = seriesEntity.component(),
              let target = seriesEntity.firstOutgoing(RepresentationOf.self),
              let timeSeries: RegularTimeSeries = target.component(),
              let stats: NumericValueStats = target.component()
        else { return }
        
        var wrap = _TimeSeriesWrapper(series: timeSeries)

        // TODO: Use style from CanvasStyle
        // TODO: Get color from series entity if not set for the series
        let color: Color
        if let key = chartSeries.colorKey,
           let seriesColor = DefaultAdaptableColors[key]
        {
            color = seriesColor
        }
        else {
            color = Color(gray: 0.5)
        }

        ImGui.PushStyleColor(ImGuiCol(ImGuiCol_FrameBg.rawValue), Color(gray: 0.0, alpha: 0.0).imVecValue)
        ImGui.PushStyleColor(ImGuiCol(ImGuiCol_PlotLines.rawValue), color.imVecValue)
        ImGui.PlotLines("##plot\(seriesEntity.runtimeID)",
                        chartValueGetter,
                        &wrap,
                        Int32(timeSeries.data.count),
                        0, // offset
                        nil, // overlay text,
                        Float.greatestFiniteMagnitude,
                        Float.greatestFiniteMagnitude,
                        plotSize)
        ImGui.PopStyleColor()
        ImGui.PopStyleColor()
    }
}

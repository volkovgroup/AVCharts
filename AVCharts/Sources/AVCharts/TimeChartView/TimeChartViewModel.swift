//
//  TimeChartViewModel.swift
//  Sample
//
//  Created by Александр Волков on 14.10.2023.
//

import Foundation

public protocol TimeChartViewModelProtocol {
    var state: TimeChartViewModel.TimeChartViewModelState { get }
    var xAxisFormatter: ((TimeChartViewModel.TimeData) -> String?)? { get }
}

extension TimeChartViewModel {
    public struct Gap {
        let measure: Calendar.Component
        
        /// Gap in Calendar.Component
        let period: Int
        let xAxisPeriod: Int
        
        var additionalSeconds: TimeInterval {
            switch measure {
            case .day:
                return TimeInterval(3600 * 24 * period)
                
            case .hour:
                return TimeInterval(3600 * period)
                
            case .minute:
                return TimeInterval(60 * period)
                
            case .weekOfMonth:
                return TimeInterval(3600 * 24 * 7 * period)
                
            case .month:
                return 0
                
            default:
                return 3600
            }
        }
    }
    
    public struct ChartData: Identifiable {
        public let id: UUID
        public var value: Double
        public let date: Date
    }
    
    public struct TimeData {
        let start: Date
        let end: Date
        let current: Date
        let measure: Calendar.Component
    }
    
    public class TimeChartViewModelState: ObservableObject {
        @Published var chartData: [ChartData] = []
        @Published var text: String? = nil
        @Published var gap: Gap
        @Published var max: Int
        
        init(gap: Gap, max: Int) {
            self.gap = gap
            self.max = max
        }
    }
}

public class TimeChartViewModel {
    public let state: TimeChartViewModelState
    public let xAxisFormatter: ((TimeData) -> String?)?
    
    init(chartData: [ChartData],
         gap: Gap,
         text: String,
         max: Int,
         xAxisFormatter: ((TimeChartViewModel.TimeData) -> String?)?
    ) {
        self.xAxisFormatter = xAxisFormatter
        state = TimeChartViewModelState(gap: gap, max: max)
        
        state.chartData = chartData
        state.text = text
    }
}

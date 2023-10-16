//
//  TimeChartView.swift
//  Sample
//
//  Created by Александр Волков on 12.10.2023.
//

import SwiftUI
import Charts

public struct TimeChartView: View {
    @StateObject private var state: TimeChartViewModel.TimeChartViewModelState
    
    var xAxisFormatter: ((TimeChartViewModel.TimeData) -> String?)?
    
    init(_ viewModel: TimeChartViewModel) {
        _state = StateObject(wrappedValue: viewModel.state)
        xAxisFormatter = viewModel.xAxisFormatter
    }
    
    @State private var animate: Bool = false
    
    private let animation = Animation
        .easeInOut(duration: 0.5)
        .delay(0.1)
    
    var view: Chart<ForEach<[TimeChartViewModel.ChartData], Date, BarMark>> {
        if state.gap.additionalSeconds != 0 {
            return Chart(state.chartData, id: \.date) { datum in
                BarMark(
                    x: .value("Time", datum.date ..< datum.date.advanced(by: state.gap.additionalSeconds)),
                    y: .value("Value", animate ? datum.value : 0)
                )
            }
        } else {
            return Chart(state.chartData, id: \.date) { datum in
                BarMark(
                    x: .value("Time", datum.date, unit: state.gap.measure),
                    y: .value("Value", animate ? datum.value : 0)
                )
            }
        }
    }
    
    public var body: some View {
        VStack {
            view
            .chartYScale(domain: [0, state.max + Int(Double(state.max) * 0.2)])
            .chartXAxis {
                AxisMarks(values: .stride(by: state.gap.measure, count: state.gap.period * state.gap.xAxisPeriod)) { value in
                    if let date = value.as(Date.self),
                       let start = state.chartData.first?.date,
                       let end = state.chartData.last?.date,
                       let text = xAxisFormatter?(.init(start: start, end: end, current: date, measure: state.gap.measure)) {
                        AxisValueLabel {
                            VStack(alignment: .leading) {
                                Text(text)
                            }
                        }
                        
                        AxisGridLine()
                        AxisTick()
                    }
                }
            }
            .if(state.text != nil) { view in
                view.chartXAxisLabel {
                    Text("\(state.text ?? "")")
                }
            }
            .onAppear {
                withAnimation(animation) {
                    animate = true
                }
            }
        }
    }    
}

extension View {
    /// Applies the given transform if the given condition evaluates to `true`.
    /// - Parameters:
    ///   - condition: The condition to evaluate.
    ///   - transform: The transform to apply to the source `View`.
    /// - Returns: Either the original `View` or the modified `View` if the condition is `true`.
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
